process mergeBam {
   tag "${sample_id}"
   cache 'lenient'
   container 'pipelinesinmegen/pipelines_inmegen:public2'
   publishDir params.out + "/merged_bam", mode:'symlink'

   input:
   tuple val(sample_id), path(bam_files)

   output:
   tuple val(sample_id), path("${sample_id}_merged.bam"),  emit: merged_bam

   script:
   """
   samtools merge -@ ${params.ncrs} -f ${sample_id}_merged.bam ${bam_files}
   """
}
