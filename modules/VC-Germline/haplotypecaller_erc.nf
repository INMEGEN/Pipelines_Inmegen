process haplotypeCallerERC {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/hc_gvcfs", mode:'copy'

    input:
    tuple val(sample_id), path(input_bam)

    output:
    tuple val(sample_id), path("${sample_id}_raw_variants.g.vcf.gz"), emit: hc_erc_out
    path("${sample_id}_raw_variants.g.vcf.gz.tbi"),                   emit: hc_erc_index

    script:
    """
    gatk HaplotypeCaller \
        -R /ref/${params.refname} \
        -I $input_bam \
        -O ${sample_id}_raw_variants.g.vcf.gz \
        -max-mnp-distance 0 \
        -ERC GVCF \
	--kmer-size 10 --kmer-size 25 --kmer-size 35 \
        --max-reads-per-alignment-start 100 \
        -G StandardAnnotation \
        -G StandardHCAnnotation \
        -G AS_StandardAnnotation
    """
}
