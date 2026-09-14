process markDuplicatesSpark {
    tag "${sample_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/dedup_sorted", mode:'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}_alineamiento.bam"), path("${sample_id}_alineamiento.bam.bai"),   emit: bam_dedup
    tuple val(sample_id), path("${sample_id}_dedup_metrics.txt"),   emit: dedup_qc

    script:
    """
    mkdir -p markduplicates/${sample_id}

    gatk MarkDuplicatesSpark \
        -I ${bam} \
        -M ${sample_id}_dedup_metrics.txt \
        -O ${sample_id}_alineamiento.bam \
        --tmp-dir markduplicates/${sample_id}
    
    rm -r markduplicates/${sample_id}
    """
}
