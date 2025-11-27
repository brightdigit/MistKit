<!--
Downloaded via https://llm.codes by @steipete on November 4, 2025 at 03:26 PM
Source URL: https://developer.apple.com/icloud/ck-tool/
Total pages processed: 1
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/icloud/ck-tool/

View in English

# Using cktool

### Before you begin

- You'll need to be a current member of the Apple Developer Program or the Apple Developer Enterprise Program in order to use `cktool`.
- Understand the concepts of Authentication, as described in Automating CloudKit Development.
- Generate a CloudKit Management Token from the CloudKit Console by choosing the Settings section for your user account. Save this token, as it will not be visible again.

### Installing the application

By default, `cktool` is distributed with Xcode starting with Xcode 13, which is available on the Mac App Store.

### General usage

`cktool` is stateless and passes all operations to the CloudKit Management API in single operations. A full list of supported operations is available from the `help` command or the `man` pages:

xcrun cktool --help
OVERVIEW: CloudKit Command Line Tool

-h, --help				Show help information.

SUBCOMMANDS: ...

### Authenticating `cktool` to CloudKit

`cktool` supports both management and user tokens, and will store them securely in Mac Keychain. You can add a token using the `save-token` command, which will launch CloudKit Console for copying of the appropriate token after prompting for information from the user:

xcrun cktool save-token			\
--type [management | user]

#### Issuing Schema Management commands

Schema Management commands require the Management Token to be provided. Once provided, `cktool` can perform the following commands:

**Reset development schema.** This allows you to revert the development database to the current production definition.

xcrun cktool reset-schema	\
--team-id [TEAM-ID]		\
--container-id [CONTAINER]

**Export schema file.** This allows you to save an existing CloudKit Database schema definition to a file, which can be kept alongside the related source code:

xcrun cktool export-schema 		\
--team-id [TEAM-ID]			\
--container-id [CONTAINER]	\
--environment [development | production]	\
[--output-file schema.ckdb]

**Import schema file.** This applies a file-based schema definition against the development database for testing.

xcrun cktool import-schema 		\
--team-id [TEAM-ID]			\
--container-id [CONTAINER]	\
--environment development 	\
--file schema.ckdb

### Issuing data commands

When a user token is available, `cktool` can access public and private databases on behalf of the user. This can be used for fetching data and inserting new records prior to integration tests. Note that due to the short lifespan of the user token, frequent interactive authentication may be required.

Querying records can be performed with the `query-records` command. Note that queries without filters require the `___recordID` to have a `Queryable` index applied, as do fields specified in the optional `--filters` argument:

xcrun cktool query-records		\
--team-id [TEAMID] 			\
--container-id [CONTAINER] 	\
--zone-name [ZONE_NAME] 		\
--database-type [public | private] 	\
--environment [development | production]	\
--record-type [RECORD_TYPE]	\
[--filters [FILTER_1] [FILTER_2]]

Where `FILTER_1` is in the form `"[FIELD_NAME] [OPERATOR] [VALUE]"`, for example `"lastname == Appleseed"`.

Inserting data is accomplished with the `create-record` command:

xcrun cktool create-record		\
--team-id [TEAM_ID]			\
--container-id [CONTAINER]	\
--zone-name [ZONE_NAME] 		\
--database-type [public | private] 	\
--environment [development | production]	\
--record-type [RECORD_TYPE]	\
[--fields-json [FIELDS_JSON]]

Where `FIELDS_JSON` is a JSON representation of the fields to set in the record. For example:

'{
"firstName": {
"type": "stringType",
"value": "Johnny"
},
"lastName": {
"type": "stringType",
"value": "Appleseed"
}
}'

---

