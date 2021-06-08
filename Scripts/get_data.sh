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
version="m0data"
# version="m1data"
# version="m2data"
# version="m3data"

# temp file is just used to remove the trailing comma at the end later on. Will be removed automatically by the script.
temp_lua_file="${version}.temp"
lua_file="${version}.lua"

# header to lua file
printf "${version} = {\n" > $temp_lua_file

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
    done < GameObjectDisplayInfo.dbc.csv

    if ([[ ! -z $filename ]]); then
        printf "{ ['id'] = \"${id}\", ['short'] = \"${short}\", ['filename'] = \"${filename}\" },\n" >> $temp_lua_file
    fi
done < gameobject_template_202106062138.csv

# remove the last trailing comma.
sed '$ s/,$//' $temp_lua_file > $lua_file

# add a footer to lua file
printf "}" >> $lua_file

# remove the temporary lua file
rm $temp_lua_file
