#!/bin/bash
#
#SBATCH --job-name=apscale
#SBATCH --constraint=rhel8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=06:00:00
#SBATCH --partition=earth-3
#SBATCH --mem=20G
#SBATCH --mail-type=end
#SBATCH --mail-user=rhyn@zhaw.ch

#rhel8module load DefaultModules
module purge
module load DefaultModules
module load gcc/9.4.0-pe5.34 miniconda3/4.12.0 lsfm-init-miniconda/1.0.0

#=================================================================================================================================================================================
# Script to run the apscale pipeline for the filtering, clusterin, denoising and taxonomicall assigning of metabarcoding sequencing data. 
# Author: Nicola Rhyner, rhyn@zhaw.ch 
# Last update: 29.07.2025
# 
# Check the file name renaming on line 67 before run!!
# Example command to run the pipeline: sbatch apscale_rhyn_29112023.sh mammals_run_0039_apscale FALSE
#
#
#  Run the script with sbatch apscale.sh <projectname> <renaming> 
#=================================================================================================================================================================================

#-------------------------------
# Step 1: Define paths and variables
#-------------------------------

	#fastq_dir=/cfs/earth/scratch/rhyn/ZHAW_MiSeq_run_0071/untrimmed_raw #path to the folder containing your fastq files. Works with gzipped and gunzipped files
	project_name=$1 #The project name of your apscale project. Must have been created prior to this script
	rename_files=$2 #set to TRUE if your input files end with <samplename>_S**_L001_R1_001.fastq.gz or <samplename>_S**_L001_R2_001.fastq.gz Set to FALSE if they end with <samplename>_R1.fastq.gz or <samplename>_R2.fastq.gz
    apscale_env=/cfs/earth/scratch/iunr/egsb/shared/conda-envs/apscale #path to your apscale conda environment with apscale, apscale-blast and all required dependencies
    apscale_project_path=/cfs/earth/scratch/rhyn/apscale_projects #path to the folder containing your apscale project(s)

# If your files have another naming then <samplename>_S**_L001_R1_001.fastq.gz, e.g. <samplename>_S**_L001_R1_001.trimmed.fastq.gz, adjust the Regex in the function FastRenamer


#-------------------------------
# Step 2: Define functions
#-------------------------------

# Define function to remove the fasts name suffix
    function FastqRenamer {
        for file in ${fastq_dir}/*.fastq{,.gz}; 
		do
		new_name=$(echo "$file" | sed -E 's/(_S[0-9]+|_L[0-9]+|_001)//g') #Adjust this regex based on your file name pattern!
		mv "$file" "$new_name"
		echo "finished renaming input fastq files"
		done
    }
	
#-------------------------------
# Step 3 prepare the apscale 
#-------------------------------

# Perform renaming if rename_files=TRUE
if [ "${rename_files}"=TRUE ]
	then
	FastqRenamer
	else 
		echo "Skipping renaming of input fastq files"
	fi

# Copy the gzipped and multiplexed fastq files into your apscale project
cp ${fastq_dir}/*.fastq{,.gz} ${apscale_project_path}/${project_name}/2_demultiplexing/data

# gzip the files if required (apscale required gzipped files..). Supress error messages if the files are already gzipped
gzip "$data_dir"/*.fastq 2>/dev/null   

# Activate apscale conda env
conda activate apscale

#-------------------------------
# Step 4 Run apscale
#-------------------------------

# run the pipeline 
apscale --run_apscale ${apscale_project_path}/${project_name} 
			
#-------------------------------
# Export a text file with all the software versions u
#-------------------------------
#>
#>>
	conda list | grep -E '^(apscale|cutadapt|blast|swarm|vsearch|apscale-blast)' > ${apscale_project_path}/${project_name}/${project_name}_software-versions_jobID${SLURM_JOB_ID}.txt
#>>
#>
		





#-------------------------------
# Deactivate Apscale 
#-------------------------------
	conda deactivate

#%#%#%#%#%#% END #%#%#%#%#%#%#%#