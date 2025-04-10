# This program provides options to download a sequence in fasta or fastq format, 
# then perform associated processing operation of the user's choice.


# Do this MANUALLY before running script:
#   anaconda2023
# Create a bioenv environment to run
#   conda create --prefix ./bioenv
# Activate the new environment
#   conda activate /home/user/bioenv
# Install entrez-direct, sra-tools, bioawk, and seqtk
#   conda install -c bioconda entrez-direct sra-tools bioawk seqtk -y


#===========================================================================================
# Function 1: Display the main menu for user to choose operation.
function main_menu(){
    while true; do
        echo
        echo MAIN MENU. PLEASE CHOOSE ONE OF THE FOLLOWING OPTIONS:
        echo Option 1: Download a FASTA file.
        echo Option 2: Download a FASTQ file.
        echo Option 3: Exit program.

        read -p "Please indicate your choice (1, 2, or 3): " user_choice_a

        if [ $user_choice_a -eq 1 ]; then
            echo You have chosen option 1: Download a FASTA file.
            downloadfasta
        elif [ $user_choice_a -eq 2 ]; then
            echo You have chosen option 1: Download a FASTQ file.
            downloadfastq
        elif [ $user_choice_a -eq 3 ]; then
            echo You have chosen to exit. Thank you for using this program. Goodbye. 
            exit
        else
            echo Invalid choice. Please try again.
        fi
    done

}


#===========================================================================================
# Function 2: Download fasta file.
function downloadfasta() {
    echo
    read -p "Enter the accession number for the FASTA sequence: " accession_num
    read -p "Please specify the database you would like to download from (nucleotide or protein): " data_base

    efetch -db $data_base -id $accession_num -format fasta > "$accession_num.fasta"

    # Check for error.
    if [ $? -ne 0 ]; then # $? is the exit status of the last run command. If run successfully, it'll return 0, otherwise it will return non-zero value.
        # If command failed, $? is not equal to 0, making this "if" condition true.
        # This would handle errors like network connection.
        echo "An error has occurred during the download. Please try again."
        retry_or_menu_fasta
    
    elif [ ! -s "$accession_num.fasta" ]; then
        # If the user provided an invalid accession number, technically the efetch command still succeeded, but return an empty file.
        # -s test if a file existed and is bigger than 0 (empty file). So " ! -s <file> " returns true when the file is empty or not exist. 
        echo "An error has occurred: The result is empty. Please check the accession number."
        retry_or_menu_fasta
    
    else
        # If efetch succeeded and the file is not empty:
        echo "Download successful!"
        fastx_processing "$accession_num.fasta"
    fi
    

}


#===========================================================================================
# Function 3: Download fastq file.
function downloadfastq() {
    echo
    read -p "Enter the accession number for the FASTQ sequence: " accession_num

    prefetch $accession_num
    fastq-dump ./$accession_num

    # Check for error.
    if [ $? -ne 0 ]; then # $? is the exit status of the last run command. If run successfully, it'll return 0, otherwise it will return non-zero value.
        # If previous command failed, provide option to retry or return to main menu.
        echo An error has occurred.
        retry_or_menu_fastq
    else
        # If previous command succeeded, then proceed with fastx_processing.
        fastx_processing "$accession_num.fastq"
    fi 
}


#===========================================================================================
# Function 4: When error occurs during download of FASTA files, provide an option to retry or return to main menu.
function retry_or_menu_fasta() {
    echo
    echo An error has occured. Would you to like to retry this task or return to main menu?
    echo Option 1: Retry this task.
    echo Option 2: Return to main menu.

    read -p "Please provide your choice: " user_choice_b

    if [ $user_choice_b -eq 1 ]; then
        echo You have chosen option 1: Retry this task.
        downloadfasta
    elif [ $user_choice_b -eq 2 ]; then
        echo You have chosen option 2: Return to main menu.
        return 0    
    else
        echo Invalid choice. Please try again.
        retry_or_menu_fasta
    fi  
}


#===========================================================================================
# Function 5: When error occurs during download of FASTQ files, provide an option to retry or return to main menu.
function retry_or_menu_fastq() {
    echo
    echo An error has occured. Would you to like to retry this task or return to main menu?
    echo Option 1: Retry this task.
    echo Option 2: Return to main menu.

    read -p "Please provide your choice: " user_choice_c

    if [ $user_choice_c -eq 1 ]; then
        echo You have chosen option 1: Retry this task.
        downloadfastq
    elif [ $user_choice_c -eq 2 ]; then
        echo You have chosen option 2: Return to main menu.
        return 0    
    else
        echo Invalid choice. Please try again.
        retry_or_menu_fastq
    fi  
}


#===========================================================================================
# Function 6: Process fastx file.
function fastx_processing() {
    fastx_file=$1

    echo
    echo Please pick one of the following options to process sequence.
    echo Option 1. Print all attributes.
    echo Option 2. Compute Reverse Complement of Sequences.
    echo Option 3. Calculate Sequence Lengths.
    echo Option 4. FASTQ ONLY - Compute Average Quality Score.
    echo Option 5. Return to Main Menu.
    
    read -p "Please indicate your choice: " user_choice_d

    if [ $user_choice_d -eq 1 ]; then
        results=$(bioawk -c fastx '{print "Name: " $name "\n" "Sequence: " $seq "\n" "Quality: " $qual "\n" "Comment: " $comment}' "$fastx_file")
        output_results "$results"
    elif [ $user_choice_d -eq 2 ]; then
        results=$(seqtk seq -r "$fastx_file")
        output_results "$results"
    elif [ $user_choice_d -eq 3 ]; then
        results=$(bioawk -c fastx '{print "Name: " $name "\n" "Length: " length($seq)}' "$fastx_file")
        output_results "$results"
    elif [ $user_choice_d -eq 4 ]; then
        results=$(bioawk -c fastx '{print "Name: " $name "\n" "Average quality score: " meanqual($qual)}' "$fastx_file")
        output_results "$results"
    elif [ $user_choice_d -eq 5 ]; then
        return 0
    
    fi
}


#===========================================================================================
# Function 7: Output option.
function output_results() {
    file=$1
    
    echo
    echo Output option. Do you want to:
    echo Option 1. Display the results on screen.
    echo Option 2. Save them to a file.
    echo Option 3. Both.
    read -p "Please indicate your choice: " user_choice_d

    if [ $user_choice_d -eq 1 ]; then
        echo "$file" 

    elif [ $user_choice_d -eq 2 ]; then
        echo "$file" > "processing_result.txt"
    
    elif [ $user_choice_d -eq 3 ]; then
        echo "$file" 
        echo "$file" > "processing_result.txt"
    
    else
        echo Invalid choice. Please try again.

    fi
}


#===========================================================================================
# Run program.
main_menu
