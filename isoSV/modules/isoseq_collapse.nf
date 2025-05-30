process ISOSEQ_COLLAPSE {

    tag "$sampleID"

    cpus 32
    memory 64.GB
    time 24.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    publishDir "${params.pubdir}/${sampleID}/", mode: "copy"

    input:
    tuple val(sampleID), path(mapped_bam)

    output:
    tuple val(sampleID), path("${sampleID}_collapsed.gff"), emit: collapse_gff
    tuple val(sampleID), path("${sampleID}_collapsed.fasta"), emit: collapse_fasta
    tuple val(sampleID), path("${sampleID}_collapsed*.txt"), emit: collapsed_txt_files
    tuple val(sampleID), path("${sampleID}_collapsed*.json"), emit: collapsed_json_files


    script:
    """
    isoseq collapse -j 32 --do-not-collapse-extra-5exons --max-5p-diff 5 --max-3p-diff 5 ${mapped_bam} ${sampleID}_collapsed.gff 
    """
}