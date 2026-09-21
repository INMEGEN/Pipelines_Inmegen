process deepVariant {
    tag "${sample}"
    cache 'lenient'
    container 'google/deepvariant:1.6.1'
    containerOptions "-v ${params.refdir}:/ref -e OMP_NUM_THREADS=${task.cpus} -e TF_NUM_INTRAOP_THREADS=${task.cpus} -e TF_NUM_INTEROP_THREADS=1"
    publishDir params.out + "/deepvariant_gvcfs", mode: 'copy'
    cpus 8
    memory '32 GB'

    input:
    tuple val(sample), path(input_bam), path(input_bai)
    path (bed_file)

    output:
    tuple val(sample), path("${sample}_dv.g.vcf.gz"), path("${sample}_dv.g.vcf.gz.tbi"), emit: dv_gvcf_out
    tuple val(sample), path("${sample}_dv.vcf.gz"),   path("${sample}_dv.vcf.gz.tbi"),   emit: dv_vcf_out

    script:
    // call_variants usa TensorFlow, que dimensiona sus pools con el numero de CPU
    // visibles y NO respeta --num_shards: por eso las variables TF_/OMP_ arriba.
    def is_wes      = "${params.wes}" == "true"
    def model       = is_wes ? "WES" : "WGS"
    def regions_opt = is_wes ? "--regions ${bed_file}" : ""
    """
    mkdir -p dv_intermediate

    /opt/deepvariant/bin/run_deepvariant \\
        --model_type=${model} \\
        --ref=/ref/${params.refname} \\
        --reads=${input_bam} \\
        --output_vcf=${sample}_dv.vcf.gz \\
        --output_gvcf=${sample}_dv.g.vcf.gz \\
        --num_shards=${task.cpus} \\
        --intermediate_results_dir=dv_intermediate \\
        ${regions_opt}

    rm -rf dv_intermediate
    """
}
