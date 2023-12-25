#!/bin/bash

html_safe() {
    local string="$1"
    string=$(echo "$string" | sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&#39;/g')
    echo "$string"
}

mkdir -p ./public
cp index2.html ./public/index.html

touch ./public/.nojekyll
rsync -av images ./public/
rsync -av render ./public/
rsync -av site_libs ./public/

ORGANIZATION=$1
REPO=$2

temp_file=$(mktemp)  
temp_file_for_links=$(mktemp) 
sidebar_temp_file=$(mktemp) # main and org level sidebar
sidebar_temp_file_2=$(mktemp) # project sidebar 2

## Sidebar content for index and org level pages
for dir in ./render/*; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")
        html_safe_dir_name=$(html_safe "$dir_name")
        html_path="${html_safe_dir_name}/index.html"
        echo -n "<li class=\"sidebar-item\"><div class=\"sidebar-item-container\"><a href=\"/${REPO}/$html_path\" class=\"sidebar-item-text sidebar-link\" >$dir_name</a ></div></li>" >> "$sidebar_temp_file"
    fi 
done

# Loop through files in the ./render directory
# render
# render/pacars
# render/botarmbots
sidebarItems=$(cat "$sidebar_temp_file")
sed -i "s|{{sidebar}}|$sidebarItems|g" "./public/index.html"
sed -i "s/{{organization}}/$ORGANIZATION/g" "./public/index.html"
sed -i "s/{{repo}}/$REPO/g" "./public/index.html"

for org_dir in ./render/*; do
    if [ -d "$org_dir" ]; then
        org_name_full=$(basename "$org_dir")
        org_name=$(html_safe "$org_name_full")
        template_file="./public/${org_name}/index.html"
        mkdir -p "./public/${org_name}"
        cp index2.html "$template_file"

        ## list sidebar items: project files
        echo "" > "$sidebar_temp_file_2"
        for project_dir_path in "$org_dir/"*; do 
            if [ -d "$project_dir_path" ]; then
                project_name=$(basename "$project_dir_path")
                project_dir=$(html_safe "$project_name")
                mkdir -p "./public/${org_name}/${project_dir}"
                #template_file="./public/${org_name}/${project_dir}/index.html"
                html_path="${org_name}/${project_dir}/index.html"
                echo -n "<li class=\"sidebar-item\"><div class=\"sidebar-item-container\"><a href=\"/${REPO}/$html_path\" class=\"sidebar-item-text sidebar-link\" >$project_name</a ></div></li>" >> "$sidebar_temp_file_2"
            fi 
        done

        # sidebarItems_2=$(cat "$sidebar_temp_file_2")
                
        sidebar_content=$(< "$sidebar_temp_file_2")
        awk -v var="$sidebar_content" '{gsub("{{sidebar}}", var)} 1' "$template_file" > temp_file && mv temp_file "$template_file"
        sed -i "s/{{organization}}/$org_name/g" "$template_file"
        sed -i "s/{{repo}}/$REPO/g" "$template_file"
        

        for project_dir_path in "$org_dir/"*; do 
            if [ -d "$project_dir_path" ]; then
                project_name=$(basename "$project_dir_path")
                project_dir=$(html_safe "$project_name")
                mkdir -p "./public/${org_name}/${project_dir}"
                template_file="./public/${org_name}/${project_dir}/index.html"
                cp index.html "${template_file}"

                sed -i "s/{{organization}}/$org_name/" "$template_file"
                sed -i "s/{{repo}}/$REPO/g" "$template_file"
                sed -i "s/{{source}}/$project_name/g" "$template_file"
                # sed -i "s|{{sidebar}}|$sidebarItems_2|g" "$template_file"
                sidebar_content=$(< "$sidebar_temp_file_2")
                awk -v var="$sidebar_content" '{gsub("{{sidebar}}", var)} 1' "$template_file" > temp_file && mv temp_file "$template_file"

                # Loop through files in the directory
                echo "" > "$temp_file"
                echo "" > "$temp_file_for_links"
                # for file in "$project_dir_path/"*; do
                #     # echo $file $project_dir_path
                #     # ls -lha -r "$file"
                #     # if [ -f "$file" ]; then
                #         filename=$(basename "$file")
                #         filename_no_extension="${filename%.*}"
                #         echo "<div class=\"quarto-layout-row quarto-layout-valign-top\"><div class=\"quarto-layout-cell quarto-layout-cell-subref\" style=\"flex-basis: 100%; justify-content: center\" ><div id=\"fig-${filename_no_extension}\" class=\"quarto-figure quarto-figure-center anchored\" ><figure class=\"figure\"><p><img src=\"/$REPO/render/${org_name_full}/${project_name}/${filename}/${filename}.png\" class=\"img-fluid figure-img\" data-ref-parent=\"fig-figure3.1\" /></p><p></p><figcaption class=\"figure-caption\"> ${filename_no_extension} </figcaption><p></p></figure></div></div></div>" >> "$temp_file"   
                #         echo "<li> <a href=\"#fig-${filename_no_extension}\" id=\"toc-${filename_no_extension}\" class=\"nav-link active\" data-scroll-target=\"#fig-${filename_no_extension}\" >${filename_no_extension}</a></li>" >> "$temp_file_for_links"   
                #     # fi
                # done
                # find "$project_dir_path" -type d 
                # basename "$project_dir_path"


                index=0
                sectionIndex=0
                sectionName=""
                subSectionName=""
                find "$project_dir_path" -type f | while read -r dir; do
                    dir_no_project_path=${dir#$project_dir_path/}
                
                    # sectionName="$first_dir"
                    # subSectionName=""
                    if [ "$dir_no_project_path" != "$dir" ]; then
                        
                        # echo "$dir_no_project_path" 
                        numDirs=$(echo $(($(echo "$dir_no_project_path" | grep -o "/" | wc -l)+1)))
                        # echo $numDirs
                        # use both cut and awk to split strings
                        first_dir=$(echo "$dir_no_project_path" | cut -d'/' -f1)
                        second_dir=$(echo "$dir_no_project_path" | awk -F'/' '{print $2}')
                        isNewSection=0 # false
                        echo "$sectionName <=:::=> $first_dir"
                        if [ "$first_dir" != "$sectionName" ]; then 
                            isNewSection=1 # true
                            sectionName="$first_dir"
                            echo "<li> <a href=\"#sec-${first_dir}\" id=\"toc-${filename_no_extension}\" class=\"nav-link active\" data-scroll-target=\"#sec-${first_dir}\" >${first_dir}</a></li>" >> "$temp_file_for_links"  
                            if [ $index  -gt 0 ]; then 
                                echo " </section>"  >> "$temp_file" 
                            fi
                            echo "<section id=\"sec-$first_dir\" class=\"level2\"><h2 class=\"anchored\" data-anchor-id=\"sec-$first_dir\"> $first_dir <a class=\"anchorjs-link\" aria-label=\"Anchor\" data-anchorjs-icon=\"\" href=\"#sec-$first_dir\" style=\"font: 1em / 1 anchorjs-icons; padding-left: 0.375em\" ></a> </h2>" >> "$temp_file" 
                            sectionIndex=$((sectionIndex + 1))

                            if [ "$subSectionName" != "" ]; then # New section starting and previous was subsection
                                # close subsection
                                echo " </section>"  >> "$temp_file"
                            fi
                            subSectionName=""
                        fi
                        # echo "$first_dir"
                        case $numDirs in
                            2)
                                ## Has section 
                                # echo "<section id=\"$sec-$first_dir\" class=\"level2\"><h2 class=\"anchored\" data-anchor-id=\"sec-$first_dir\"> $first_dir <a class=\"anchorjs-link\" aria-label=\"Anchor\" data-anchorjs-icon=\"\" href=\"#sec-$first_dir\" style=\"font: 1em / 1 anchorjs-icons; padding-left: 0.375em\" ></a> </h2>" >> "$temp_file"   
                                echo "<div id=\"fig-$first_dir\" class=\"quarto-layout-panel\" data-nrow=\"1\"> <figure class=\"figure\">"  >> "$temp_file" 
                                echo "<div class=\"quarto-layout-row quarto-layout-valign-top\"><div class=\"quarto-layout-cell quarto-layout-cell-subref\" style=\"flex-basis: 100%; justify-content: center\" ><div id=\"fig-${first_dir}\" class=\"quarto-figure quarto-figure-center anchored\" ><figure class=\"figure\"><p><img src=\"/$REPO/render/${org_name_full}/${project_name}/$dir_no_project_path\" class=\"img-fluid figure-img\" data-ref-parent=\"fig-$first_dir\" /></p><p></p><figcaption class=\"figure-caption\"> ${first_dir} </figcaption><p></p></figure></div></div></div>" >> "$temp_file" 
                                echo "<figcaption class=\"figure-caption\"> $first_dir </figcaption> <p></p> </figure> </div>"  >> "$temp_file"                                   
                                # echo " </section>"  >> "$temp_file"      
                                                              
                                ;;
                            3)
                                ## Has section 
                                ## Has sub section
                                echo "$subSectionName <==> $second_dir"
                                if [ "$subSectionName" != "$second_dir" ]; then 
                                    subSectionName="$second_dir"
                                    echo "<section id=\"sec-$second_dir\" class=\"level3\"><h3 class=\"anchored\" data-anchor-id=\"sec-$second_dir\"> $second_dir <a class=\"anchorjs-link\" aria-label=\"Anchor\" data-anchorjs-icon=\"\" href=\"#sec-$second_dir\" style=\"font: 1em / 1 anchorjs-icons; padding-left: 0.375em\" ></a> </h3>" >> "$temp_file" 
                                    # Create new subsection
                                else 
                                    filename=$(basename "$dir_no_project_path")
                                    filename_no_extension="${filename%.*}"
                                    echo "<div id=\"fig-$filename_no_extension\" class=\"quarto-layout-panel\" data-nrow=\"1\"> <figure class=\"figure\">"  >> "$temp_file" 
                                    echo "<div class=\"quarto-layout-row quarto-layout-valign-top\"><div class=\"quarto-layout-cell quarto-layout-cell-subref\" style=\"flex-basis: 100%; justify-content: center\" ><div id=\"fig-${filename_no_extension}\" class=\"quarto-figure quarto-figure-center anchored\" ><figure class=\"figure\"><p><img src=\"/$REPO/render/${org_name_full}/${project_name}/$dir_no_project_path\" class=\"img-fluid figure-img\" data-ref-parent=\"fig-$filename_no_extension\" /></p><p></p><figcaption class=\"figure-caption\"> ${filename_no_extension} </figcaption><p></p></figure></div></div></div>" >> "$temp_file" 
                                    echo "<figcaption class=\"figure-caption\"> $filename_no_extension </figcaption> <p></p> </figure> </div>"  >> "$temp_file"
                                fi
                                ;;
                                
                            *)
                                ;;
                        esac
                        index=$((index + 1))
                    fi
                done


                sed -i "s/{{section}}/$(sed 's:/:\\/:g' $temp_file | tr -d '\n')/g" "$template_file"
                sed -i "s/{{links}}/$(sed 's:/:\\/:g' $temp_file_for_links | tr -d '\n')/g" "$template_file"
            fi
        done
    fi
done