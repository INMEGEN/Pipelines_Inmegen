process glnexus {
    tag "${project_id}"
    cache 'lenient'
    container 'ghcr.io/dnanexus-rnd/glnexus:v1.4.3'
    publishDir params.out + "/glnexus_vcf", mode: 'copy'
    cpus 8
    memory '64 GB'

    input:
    path(gvcf_files)
    path(tbi_files)
    val(project_id)
    file(interval_list)

    output:
    tuple val(project_id), path("${project_id}_dv_joint.vcf.gz"), path("${project_id}_dv_joint.vcf.gz.tbi"), emit: dv_joint_vcf

    script:
    // Sin --mem-gbytes glnexus toma ~2/3 de la RAM del SISTEMA e ignora el limite del contenedor.
    def is_wes  = "${params.wes}" == "true"
    def bed_opt = is_wes ? "--bed ${interval_list}" : ""
    def config  = is_wes ? "DeepVariantWES" : "DeepVariant"
    def memgb   = task.memory ? (task.memory.toGiga() * 0.9) as int : 48
    """
    ls *.g.vcf.gz > gvcf.list

    glnexus_cli \\
        --config ${config} \\
        ${bed_opt} \\
        --threads ${task.cpus} \\
        --mem-gbytes ${memgb} \\
        --dir GLnexus.DB \\
        \$(cat gvcf.list | tr '\\n' ' ') \\
    | bcftools view -Oz -o ${project_id}_dv_joint.vcf.gz

    tabix ${project_id}_dv_joint.vcf.gz
    rm -rf GLnexus.DB
    """
}
