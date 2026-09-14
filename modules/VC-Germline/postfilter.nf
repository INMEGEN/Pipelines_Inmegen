process postfiltervcf {
    tag "${project_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public'
    publishDir params.out + "/clinical_vcf", mode: 'copy'

    input:
    tuple val(project_id), path(vcf), path(tbi)

    output:
    tuple val(project_id), path("${project_id}_clinical_pass.vcf.gz"), path("${project_id}_clinical_pass.vcf.gz.tbi"), emit: filt_pass_vcf

    script:

    // Umbrales de calidad por genotipo (definidos en nextflow.config)
    // min_gq : calidad mínima del genotipo
    // min_dp : profundidad mínima (clínico >=20, investigación >=10)
    // ab_min / ab_max : rango de balance alélico permitido en heterocigotos

    """
    bcftools view -f "PASS" ${vcf} |
    bcftools filter \
            -i 'FMT/GQ >= ${params.min_gq} &&
            FMT/DP >= ${params.min_dp} &&
            (FMT/AD[0:1])/(FMT/DP) >= ${params.ab_min} &&
            (FMT/AD[0:1])/(FMT/DP) <= ${params.ab_max}' \
        -Oz -o ${project_id}_clinical_pass.vcf.gz

    tabix ${project_id}_clinical_pass.vcf.gz
    """
}
