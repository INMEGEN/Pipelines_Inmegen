process splitVCFs {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/vcfs_persample" , mode:'copy'

    input:
    tuple val(project_id), path(vcf_file), path(vcf_index)
    val(type)

    output:
    path("${type}_vcfs/*_${type}.vcf.gz*"),    emit: vcf_persample

    script:
    """ 
    mkdir -p tmp/splitvcf
    mkdir ${type}_vcfs

    for sample in `bcftools query -l ${vcf_file}`
    do
    gatk SelectVariants -R /ref/${params.refname} -V ${vcf_file} -O \${sample}_${type}.vcf.gz -sn \${sample} --exclude-non-variants true --tmp-dir tmp/splitvcf 
    done
    
    mv *_${type}.vcf.gz* ${type}_vcfs/
   
    rm -r tmp/splitvcf
    """
}
