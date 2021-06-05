#!/bin/bash

# The purpose of this script is to pull data from the GameObjectDisplayInfo.dbc.csv and gameobject_template. 
# I've included the versions that I used in this directory. This was a quickly written script - and it may
# have problems. But it seemed to work for the most part during testing.

# GameObjectDisplayInfo.dbc.csv was extracted from the client. gameobject_template was from the M3 database.

header="m3data = {\n\n"
body=""
footer="\n}"

printf $header > m3data.txt

while IFS=, read -r entry displayId name
do
    id=$entry
    short=$name
    while IFS=, read -r Id ModelName
    do
        if [ $Id = $displayId ]; then
            filename=$(echo $ModelName | sed 's,\\,\\\\\\\\,g')
            break
        fi
    done < GameObjectDisplayInfo.dbc.csv
    printf "{ ['id'] = \"${id}\", ['short'] = \"${short}\", ['filename'] = \"${filename}\" },\n" >> m3data.txt
done < gameobject_template_202104172334.csv

printf $footer >> m3data.txt

# Remember to remove trailing comma on last line.
