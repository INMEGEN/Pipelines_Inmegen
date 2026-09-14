process deepVariant {
    cache 'lenient'
    container 'google/deepvariant:1.6.1'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/deepvariant_gvcfs", mode: 'copy'

    input:
    tuple val(sample), path(input_bam), path(input_bai)
    path (bed_file)

    output:
    tuple val(sample), path("${sample}_dv.g.vcf.gz"), path("${sample}_dv.g.vcf.gz.tbi"), emit: dv_gvcf_out
    tuple val(sample), path("${sample}_dv.vcf.gz"),   path("${sample}_dv.vcf.gz.tbi"),   emit: dv_vcf_out

    script:
    def model = params.wes ? "WES" : "WGS"
    def regions_opt = params.wes ? "--regions ${bed_file}" : ""
    """
    /opt/deepvariant/bin/run_deepvariant \
        --model_type=${model} \
        --ref=/ref/${params.refname} \
        --reads=${input_bam} \
        --output_vcf=${sample}_dv.vcf.gz \
        --output_gvcf=${sample}_dv.g.vcf.gz \
        --num_shards=${params.ncrs} \
        ${regions_opt}
    """
}
