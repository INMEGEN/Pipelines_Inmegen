process variantQC {
   cache 'lenient'
   publishDir params.out , mode: 'copy'

   input:
   tuple val(project_id), path(join_vcf), path(vcf_index)

   output:
   tuple val(project_id), path("variant_stats/${project_id}_variantQC.html"), emit: summary_QC

   script:
   """
   mkdir -p variant_stats

   cp ${join_vcf} ${vcf_index} variant_stats/

   docker run --cpus ${params.ncrs} --user="\$(id -u):\$(id -g)" -v \$PWD/variant_stats:/data -v "${params.refdir}":/ref ghcr.io/bimberlab/discvrseq:latest VariantQC \
                -R /ref/${params.refname} \
                -V /data/${join_vcf} \
                -O /data/${project_id}_variantQC.html \
                --threads ${params.ncrs}

   cd variant_stats/
   rm ${join_vcf} ${vcf_index}
   """
}
