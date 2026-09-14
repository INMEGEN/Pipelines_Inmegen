process align {
    tag "${sample_id}_${PU}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/aligned_reads", mode:'symlink'
    cpus params.ncrs ?: 6

    input:
    tuple val(sample), val(sample_id), val(PU), val(PL), val(LB), path(R1), path(R2)

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"),  emit: aligned_reads

    script:

    // Read Group en GATK Best Practices:
    // ID: identificador por read group (sample + platform unit)
    // SM: nombre de muestra 
    // PU: platform unit (flowcell.lane.barcode)
    // PL: plataforma
    // LB: librería (para detección de duplicados)
    
    def readGroup = "@RG\\tID:${sample_id}.${PU}\\tPU:${PU}\\tPL:${PL}\\tLB:${LB}\\tSM:${sample_id}"
    
    """
    set -euo pipefail

    bwa mem -K 100000000 \\
        -v 3 \\
        -t ${task.cpus} \\
        -Y \\
        -R \"${readGroup}\" \\
        /ref/${params.refname} \\
        ${R1} \\
        ${R2} \\
    | samtools sort \\
        -@ ${task.cpus} \\
        -O bam \\
        -o ${sample_id}.sorted.bam \\
    """
}
