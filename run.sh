RUNTIME_ASMDEF_NAME=$(echo "$INPUT_COMPANY_NAME"."$INPUT_PACKAGE_NAME" | sed 's/ //g')
EDITOR_ASMDEF_NAME="$RUNTIME_ASMDEF_NAME".Editor
RUNTIME_TESTS_ASMDEF_NAME="$RUNTIME_ASMDEF_NAME".Tests
EDITOR_TESTS_ASMDEF_NAME="$RUNTIME_ASMDEF_NAME".Editor.Tests
PACKAGE_JSON_PATH="$INPUT_PACKAGE_ROOT_PATH"/package.json

if [ -n "$INPUT_FULL_NAME" ]; then
	FULL_NAME="$INPUT_FULL_NAME"
else
	FULL_NAME=$(echo "$INPUT_DOMAIN_EXTENSION"."$RUNTIME_ASMDEF_NAME" | tr '[:upper:]' '[:lower:]')
	echo "Notice: Full package name was not provided so generated name '$FULL_NAME' will be used"
fi

jq ".name = \"$FULL_NAME\" | .displayName = \"$INPUT_PACKAGE_NAME\"" "$PACKAGE_JSON_PATH" > temp.json && mv temp.json "$PACKAGE_JSON_PATH"

function rename_asmdef() {
	local ASMDEF=$1
	local RENAMED_ASMDEF=$2
	
	echo "Renaming $ASMDEF to $RENAMED_ASMDEF" >&2
	mv "$ASMDEF" "$RENAMED_ASMDEF"
	
	if [ -f "$ASMDEF".meta ]; then
		mv "$ASMDEF".meta "$RENAMED_ASMDEF".meta
	else
		echo "Notice: No '.meta' file for "$ASMDEF" was found to rename." >&2
	fi
}

function find_and_rename_asmdef() {
	local DIRECTORY=$1
	local NEW_NAME=$2
	
	if [ -d "$DIRECTORY" ]; then
		ASMDEF=$(find "$DIRECTORY" -maxdepth 1 -name "*.asmdef" -type f -print -quit)
		if [ -n "$ASMDEF" ]; then
			RENAMED_ASMDEF=$(dirname "$ASMDEF")/"$NEW_NAME".asmdef
			rename_asmdef "$ASMDEF" "$RENAMED_ASMDEF"
			echo "$RENAMED_ASMDEF"
		else
			echo "Notice: Expected '.asmdef' files was not found in directory '$DIRECTORY'." >&2
		fi
	else
		echo "Notice: Directory expected to contain a '.asmdef' file, '$DIRECTORY' does not exits." >&2
	fi
}

RUNTIME_ASMDEF=$(find_and_rename_asmdef "$INPUT_PACKAGE_ROOT_PATH"/Runtime "$RUNTIME_ASMDEF_NAME")
EDITOR_ASMDEF=$(find_and_rename_asmdef "$INPUT_PACKAGE_ROOT_PATH"/Editor "$EDITOR_ASMDEF_NAME")
RUNTIME_TESTS_ASMDEF=$(find_and_rename_asmdef "$INPUT_PACKAGE_ROOT_PATH"/Tests/Runtime "$RUNTIME_TESTS_ASMDEF_NAME")
EDITOR_TESTS_ASMDEF=$(find_and_rename_asmdef "$INPUT_PACKAGE_ROOT_PATH"/Tests/Editor "$EDITOR_TESTS_ASMDEF_NAME")

declare -A OLD_TO_NEW_REFERENCES

function update_asmdef_content() {
	local ASMDEF_FILE=$1
	local ASMDEF_NAME=$2

	OLD_TO_NEW_REFERENCES["$(jq '.name' "$ASMDEF_FILE")"]="$ASMDEF_NAME"

	jq ".name = \"$ASMDEF_NAME\"" "$ASMDEF_FILE" > temp.json && mv temp.json "$ASMDEF_FILE"
	echo "Updated name entry of "$ASMDEF_FILE" to "$ASMDEF_NAME""

	function update_references() {
		local OLD_REFERENCE=$1
		local NEW_REFERENCE=$2

		jq -c '.references | to_entries[]' "$ASMDEF_FILE" | while read -r entry; do
			INDEX=$(echo $entry | jq '.key')
			VALUE=$(echo $entry | jq -r '.value')

			if [ "$VALUE" == "$OLD_REFERENCE" ]; then
				jq ".references[$INDEX] |= \"$NEW_REFERENCE\"" "$ASMDEF_FILE" > temp.json && mv temp.json "$ASMDEF_FILE"
				break
			fi
		done
	}

	# Return if the asmdef file has no references to update
	if ! jq -e 'has("references")' "$ASMDEF_FILE" >/dev/null 2>&1; then 
		return; 
	fi

	for OLD_REFERENCE in "${!OLD_TO_NEW_REFERENCES[@]}"; do
		NEW_REFERENCE=${OLD_TO_NEW_REFERENCES[$OLD_REFERENCE]}
		OLD_REFERENCE=$(echo "$OLD_REFERENCE" | tr -d '"')
		update_references $OLD_REFERENCE $NEW_REFERENCE
	done
}

if [ -n "$RUNTIME_ASMDEF" ]; then
	update_asmdef_content "$RUNTIME_ASMDEF" "$RUNTIME_ASMDEF_NAME"
fi

if [ -n "$EDITOR_ASMDEF" ]; then
	update_asmdef_content "$EDITOR_ASMDEF" "$EDITOR_ASMDEF_NAME"
fi

if [ -n "$RUNTIME_TESTS_ASMDEF" ]; then
	update_asmdef_content "$RUNTIME_TESTS_ASMDEF" "$RUNTIME_TESTS_ASMDEF_NAME"
fi

if [ -n "$EDITOR_TESTS_ASMDEF" ]; then
	update_asmdef_content "$EDITOR_TESTS_ASMDEF" "$EDITOR_TESTS_ASMDEF_NAME"
fi