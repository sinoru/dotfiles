if (( $+commands[xattr] )); then
    mdsync() {
        if [[ $# -ne 2 ]]; then
            echo "Usage: ${funcstack[1]} source destination" >&2
            return 1
        fi

        source_xattr_keys=(${(f)"$(xattr $1)"})
        destination_xattr_keys=(${(f)"$(xattr $2)"})

        typeset -A source_xattrs=()

        for key in $source_xattr_keys; do
            if (( $destination_xattr_keys[(Ie)key] )); then
                echo "${funcstack[1]}: Duplicated key $key" >&2
                return 1
            elif [[ $key != com.apple.metadata:* ]]; then
                continue
            fi

            source_xattrs[$key]=$(xattr -p -s -x $key $1)
        done

        for key value in ${(kv)source_xattrs}; do
            xattr -w -s -x $key $value $2
        done
    }

    if (( $+commands[plutil] )); then
        mdsource() {
            case $1 in
                -p|--print)
                    shift
                    if [[ $# -ne 1 ]]; then
                        echo "Usage: ${funcstack[1]} -p file" >&2
                        return 1
                    fi

                    xattr -p -s -x com.apple.metadata:kMDItemWhereFroms $1 | xxd -r -p | plutil -p -
                    ;;
                -w|--write|-a|--append)
                    [[ $1 == -a || $1 == --append ]] && append=true || append=false
                    shift

                    if [[ $# -ne 2 ]]; then
                        echo "Usage: ${funcstack[1]} -w|-a value file" >&2
                        return 1
                    fi

                    old_hex_value=$(xattr -p -s -x com.apple.metadata:kMDItemWhereFroms $2 2>/dev/null)
                    if [[ $append == true && -n $old_hex_value ]]; then
                        tmp=$(mktemp -t "${funcstack[1]}")
                        if [ $? -ne 0 ]; then
                            echo "${funcstack[1]}: Can't create temp file, exiting..."
                            return 1
                        fi

                        echo "$old_hex_value" | xxd -r -p | plutil -convert xml1 - -o "$tmp"

                        /usr/libexec/PlistBuddy -c "Add : string $1" "$tmp"

                        xattr -w -s -x com.apple.metadata:kMDItemWhereFroms "$(plutil -convert binary1 "$tmp" -o - | xxd -p -c 0)" $2

                        rm "$tmp"
                    elif [[ $append != true && -z $old_hex_value ]]; then
                        xattr -w -s -x com.apple.metadata:kMDItemWhereFroms "$(echo "<array><string>$1</string></array>" | plutil -convert binary1 - -o - | xxd -p -c 0)" $2
                    else
                        return 1;
                    fi
                    ;;
                *)
                    echo "Usage: ${funcstack[1]} -p|-w|-a" >&2
                    return 1;
                    ;;
            esac
        }
    fi
fi
