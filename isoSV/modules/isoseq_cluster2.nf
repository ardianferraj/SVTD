process ISOSEQ_CLUSTER {

    tag "$sampleID"

    cpus 32
    memory 48.GB
    time 24.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    container = "/projects/chesler-lab/csna/sv_ferraj/SVTD/repo/isoSV/containers/isoSV.sif"

    publishDir "${params.pubdir}/${sampleID}/", mode: "copy"

    input:
    tuple val(sampleID), path(flnc_bam)

    output:
    tuple val(sampleID), path("${sampleID}.clustered.bam"), emit: clustered_bam
    tuple val(sampleID), path("${sampleID}.clustered.bam.pbi"), emit: clustered_bam_index
    tuple val(sampleID), path("${sampleID}.clustered.cluster_report.csv"), emit: cluster_report

    script:
    """
    isoseq cluster2 \
    -j 32 \
    ${flnc_bam} \
    ${sampleID}.clustered.bam
    """
}