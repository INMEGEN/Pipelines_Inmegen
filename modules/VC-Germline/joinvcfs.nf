process joinvcfs {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/filtered_vcfs", mode:'copy'

    input:
    tuple val(project_id), path(vcf_snps)  , path(vcf_snps_index)
    tuple val(project_id2), path(vcf_indels), path(vcf_indels_index)

    output:
    tuple val(project_id), path("${project_id}_filtered.vcf.gz"), path("${project_id}_filtered.vcf.gz.tbi"),  emit: join_vars_filt

    script:
    """
 # Reordenar SNPs según sequence dictionary del reference
    gatk SortVcf \
        -I ${vcf_snps} \
        -O ${project_id}_snps_sorted.vcf.gz \
        -SD /ref/${params.refname.replace('.fasta','.dict')}

    # Reordenar indels según sequence dictionary del reference
    gatk SortVcf \
        -I ${vcf_indels} \
        -O ${project_id}_indels_sorted.vcf.gz \
        -SD /ref/${params.refname.replace('.fasta','.dict')}

    # Mergear VCFs ya ordenados
    gatk MergeVcfs \
        -I ${project_id}_snps_sorted.vcf.gz \
        -I ${project_id}_indels_sorted.vcf.gz \
        -O ${project_id}_filtered.vcf.gz
    """
}
