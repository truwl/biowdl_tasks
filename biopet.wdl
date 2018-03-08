task FastqSplitter {
    File inputFastq
    String outputPath
    Int numberChunks
    File tool_jar

    command {
    mkdir -p ${sep=' ' prefix(outputPath + "/chunk_", range(numberChunks))}
    ${if (numberChunks > 1) then ("java -jar " + tool_jar + " -I " + inputFastq + write_lines(prefix("-o ", range(numberChunks))))
    else ("ln -sf " + inputFastq + " " + outputPath + "/chunk_0/" + basename(inputFastq))}
    }

    output {
        Array[File] outputFastqFiles = glob(outputPath + "/chunk_*/" + basename(inputFastq))
    }
}

task ScatterRegions {
    File ref_fasta
    File ref_dict
    String outputDirPath
    File tool_jar
    Int? scatterSize
    File? regions

    command {
        mkdir -p ${outputDirPath}
        java -Xmx2G -jar ${tool_jar} \
          -R ${ref_fasta} \
          -o ${outputDirPath} \
          ${"-s " + scatterSize} \
          ${"-L " + regions}
    }

    output {
        Array[File] scatters = glob(outputDirPath + "/scatter-*.bed")
    }
}

task SampleConfig {
    File tool_jar
    Array[File]+ inputFiles
    String? sample
    String? library
    String? readgroup
    String? jsonOutputPath
    String? tsvOutputPath

    command {
        mkdir -p . $(dirname ${jsonOutputPath}) $(dirname ${tsvOutputPath})
        java -jar ${tool_jar} \
        -i ${sep="-i " inputFiles} \
        ${"--sample " + sample} \
        ${"--library " + library} \
        ${"--readgroup " + readgroup} \
        ${"--jsonOutput " + jsonOutputPath} \
        ${"--tsvOutput " + tsvOutputPath}
    }

    output {
        Array[String] keys = read_lines(stdout())
        File? jsonOutput = jsonOutputPath
        File? tsvOutput = tsvOutputPath
        Object values = if (defined(tsvOutput) && size(tsvOutput) > 0) then read_map(tsvOutput) else { "": "" }
    }
}

task DownloadSampleConfig {
    File? inputJar
    String? version = "0.1"

    command {
        ${if defined(inputJar) then "echo ${inputJar}" else "wget https://github.com/biopet/sampleconfig/releases/download/v${version}/SampleConfig-assembly-${version}.jar"}
    }

    output {
        File jar = if defined(inputJar) then select_first([inputJar]) else ("SampleConfig-assembly-" + version + ".jar")
    }
}
