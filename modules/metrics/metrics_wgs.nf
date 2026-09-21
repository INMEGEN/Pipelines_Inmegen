process metricswgs {
    tag "${sample_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/metrics", mode: 'copy'
    cpus 4
    memory '12 GB'

    input:
    tuple val(sample_id), path(input_bam), path(bam_idx)

    output:
    tuple val(sample_id), path("summary/${sample_id}_QCmetrics.txt"), emit: summary_file
    path("${sample_id}*")

    script:
    """
    mkdir -p summary

    samtools coverage -w 32 -o ${sample_id}_cov_hist.txt ${input_bam}

    mosdepth -t ${task.cpus} -n --fast-mode -b 500 --thresholds 0,1 ${sample_id} ${input_bam}

    zcat ${sample_id}.thresholds.bed.gz | awk '{print \$(NF-1)"\\t"\$NF}' > ${sample_id}_thresholds.txt

    dpth=\$(grep "total_region" ${sample_id}.mosdepth.summary.txt | awk -F'\\t' '{print \$4"x"}')

    totalbases=\$(awk '{split(\$0,a,"\\t"); sum += a[1]} END {print sum}' ${sample_id}_thresholds.txt)
    ontargetbases=\$(awk '{split(\$0,a,"\\t"); sum += a[2]} END {print sum}' ${sample_id}_thresholds.txt)

    Bontarget=\$(awk "BEGIN {x=\$totalbases; if(x==0) print 0; else print \$ontargetbases/x}")
    Bontargetp=\$(awk "BEGIN {x=\$Bontarget; y=100; print x*y}")

    canonicos=\$(grep -n "chrY" ${sample_id}.mosdepth.region.dist.txt | cut -d":" -f1 | tail -n 1)
    if [ -n "\$canonicos" ]; then
        head -n \$canonicos ${sample_id}.mosdepth.region.dist.txt > ${sample_id}_canonicos.mosdepth.region.dist.txt
        mv ${sample_id}_canonicos.mosdepth.region.dist.txt ${sample_id}.mosdepth.region.dist.txt
    fi

    echo -e "${sample_id}\\t\$dpth\\t\$totalbases\\t\$ontargetbases\\t\$Bontargetp" \
        >> summary/${sample_id}_QCmetrics.txt
    """
}
