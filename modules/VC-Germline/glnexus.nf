process glnexus {
    cache 'lenient'
    container 'ghcr.io/dnanexus-rnd/glnexus:v1.4.3'
    publishDir params.out + "/glnexus_vcf", mode: 'copy'
    memory '64 GB'

    input:
    path(gvcf_files)
    path(tbi_files)
    val(project_id)
    file(interval_list)

    output:
    tuple val(project_id), path("${project_id}_dv_joint.vcf.gz"), path("${project_id}_dv_joint.vcf.gz.tbi"), emit: dv_joint_vcf

    script:
    def bed_opt = params.wes == "true" ? "--bed ${interval_list}" : ""
    def config  = params.wes == "true" ? "DeepVariantWES" : "DeepVariant"
    """
    ls *.g.vcf.gz > gvcf.list

    glnexus_cli \
        --config ${config} \
        ${bed_opt} \
        --threads ${params.ncrs} \
        --dir GLnexus.DB \
        \$(cat gvcf.list | tr '\\n' ' ') \
    | bcftools view -Oz -o ${project_id}_dv_joint.vcf.gz

    tabix ${project_id}_dv_joint.vcf.gz
    rm -rf GLnexus.DB
    """
}
