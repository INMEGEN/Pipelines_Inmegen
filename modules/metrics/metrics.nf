process Metrics {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public'
    publishDir params.out + "/metrics", mode:'copy'

    input:
    tuple val(pair_id), path(sorted_dedup_reads)

    output:
    tuple val(pair_id), path("${pair_id}_depth_out.txt"), \
                        path("${pair_id}_cov_hist.txt"),  emit: metrics_ch

    script:
    """
    samtools depth -a ${sorted_dedup_reads} > ${pair_id}_depth_out.txt
    samtools coverage -w 32 -o ${pair_id}_cov_hist.txt ${sorted_dedup_reads}
    """
}

