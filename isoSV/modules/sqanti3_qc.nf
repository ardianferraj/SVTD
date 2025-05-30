process SQANTI3_QC {

    tag "$sampleID"

    cpus 16
    memory 32.GB
    time 24.h
    errorStrategy {(task.exitStatus == 140) ? { log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    container = "/projects/chesler-lab/csna/sv_ferraj/SVTD/repo/isoSV/containers/isoSV.sif"

    publishDir "${params.pubdir}/${sampleID}/sqanti3", mode: "copy"

    input:
    tuple val(sampleID), 
          path(collapsed_fasta), 
          path(reference_gtf), 
          path(reference_fasta), 
          path(optional_shortread_fofn)

    output:
    tuple val(sampleID), 
          path("${sampleID}_sqanti_classification.txt"), 
          path("${sampleID}_sqanti_junctions.txt"), 
          emit: sqanti_qc_output

    script:
    """
    python  \\
        ${collapsed_fasta} \\
        ${reference_gtf} \\
        ${reference_fasta} \\
        -t ${task.cpus} \\
        -o ${sampleID}_sqanti \\
        -d ./ \\
        --short_reads ${optional_shortread_fofn}
    """
}
