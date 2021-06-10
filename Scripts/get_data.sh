#!/bin/bash

################################## INFORMATION ##################################
# The purpose of this script is to pull data from the GameObjectDisplayInfo.dbc.csv and gameobject_template. 
# I've included the versions that I used in this directory. This was a quickly written script - and it may
# have problems. But it seemed to work for the most part during testing.

# GameObjectDisplayInfo.dbc.csv
# > Extracted from the client.
# > Using only the following columns:
# >>> Id
# >>> ModelName

# gameobject_template
# > Exported from the database.
# > Using only the following columns:
# >>> entry
# >>> displayId
# >>> name
################################ END INFORMATION ################################


### Choose one below as desired.
version=0
# version=1
# version=2
# version=3

# the m0data file needed for the addon data.
lua_file="m${version}data.lua"

# temp file is just used to remove the trailing comma at the end later on. Will be removed automatically by the script.
temp_lua_file="${lua_file}.temp"

# GameObjectDisplayInfo.dbc.csv filename
godi_name="GameObjectDisplayInfo.dbc.${version}.csv"

# gameobject_template.csv filename
got_name="gameobject_template.${version}.csv"

# header to lua file
printf "m${version}data = {\n" > $temp_lua_file

# body of lua file
while IFS=, read -r entry displayId name
do
    id=$entry
    short=$(echo $name | sed 's/["]//g')
    
    while IFS=, read -r Id ModelName
    do
        if ([ $Id = $displayId ]); then
            filename=$(echo $ModelName | sed 's,\\,\\\\\\\\,g')
            break
        fi
    done < $godi_name

    if ([[ ! -z $filename ]]); then
        printf "{ ['id'] = \"${id}\", ['short'] = \"${short}\", ['filename'] = \"${filename}\" },\n" >> $temp_lua_file
    fi
done < $got_name

# remove the last trailing comma.
sed '$ s/,$//' $temp_lua_file > $lua_file

# add a footer to lua file
printf "}" >> $lua_file

# remove the temporary lua file
rm $temp_lua_file