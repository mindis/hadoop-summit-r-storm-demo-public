#!/usr/local/bin/r -i

#when installed
library(Storm,quietly=TRUE)
#library(rjson);

#for now
#source("Storm/R/Storm.R");

Storm = setRefClass("Storm",
                    fields = list(
                      tuple = "Tuple",
                      setup = "list",
                      lambda="function"
                    )
);

#Storm$methods(
# lambda = function(s=Storm) {
# s$log(c("skipping tuple id='",s$tuple$id,"'"));
# }
#);
#Storm$lambda = function(s) {
# s$log(c("skipping tuple id='",s$tuple$id,"'"));
#};

Storm$methods(
  initialize = function() {
    #.self$lambda = Storm$lambda;
    .self$lambda = function(s) {
      s$log(c("skipping tuple id='",s$tuple$id,"'"));
    };
    .self;
  }
);

Storm$methods(
  run = function() {
    buf = "";

    x.stdin = file("stdin");
    open(x.stdin);

    #x.stdout = file("stdout");
    #cat(paste('{"pid": ',Sys.getpid(),'}',"\n",sep=""),file=x.stdout);
    cat(paste('{"pid": ',Sys.getpid(),'}',"\nend\n",sep=""));
    #cat('{"command": "emit", "anchors": [], "tuple": ["bolt initializing"]}\nend\n');
    #flush(x.stdout);
    #close(x.stdout);

    while (TRUE) {
      rl = as.character(readLines(con=x.stdin,n=1,warn=FALSE));
      if (length(rl) == 0) {
        close(x.stdin);
        break;
      }
      if (rl == "end" || rl == "END") {
        #print(buf);
        .self$process_json(buf);
        buf = "";
      } else {
        buf = paste(buf,rl,"\n",sep="");
      }
    }
    cat('{"command": "emit", "anchors": [], "tuple": ["bolt initializing4"]}\nend\n');
  }
);

Storm$methods(
  process_json = function(json=character) {
    t = NULL;
    if (is.list(json)) {
      t = fromJSON(unlist(json));
    }
    else {
      t = fromJSON(json);
    }
    # we assume that it is a tuple if the "tuple" field is not empty.
    if (is.list(t)) {
        if (!is.null(t$tuple)) {
            .self$process_tuple(json);
        }
                                        # we assume that it is a setup if the "pidDir" field is not empty.
        else if (!is.null(t$pidDir)) {
            .self$setup = t;
            .self$process_setup(t);
        }
                                        # otherwise, not sure what it is. log an error and stop.
        else {
                                        #TODO .self$log(paste("unrecognized JSON:\n'",json,"'\n",sep=""));
                                        #stop("unrecognized JSON: ",json);
        }
    }
  }
);

Storm$methods(
  process_tuple = function(json=character) {
    #print(Tuple);
    #tuple = getRefClass("Tuple")$new();
    tt = Tuple$new();
    tt$parse(json);
    .self$tuple = tt;
    .self$lambda(.self);
    # print(.self$input.tuple);
  }
);
Storm$methods(
  process_setup = function(json=character) {
    file.create(paste(json$pidDir,"/",Sys.getpid(),sep=""))
    # print(.self$input.setup);
  }
);

Storm$methods(
  log = function(msg=character) {
    cat(c(
      '{',
      '"command": "log",',
      '"msg": "',msg,'"',
      '}\n',
      'end\n'
    ),sep="");
  }
);
Storm$methods(
  ack = function(tuple=Tuple) {
    #x.stdout = file("stdout");
    cat(c(
      '{\n',
      '\t"command": "ack",\n',
      '\t"id": "',tuple$id,'"\n',
      '}\n',
      'end\n'
    ),sep="")#,file=x.stdout);
    #flush(x.stdout);
    #close(x.stdout);
  }
);
Storm$methods(
  fail = function(tuple=Tuple) {
    cat(c(
      '{',
      '"command": "fail",',
      '"id": "',tuple$id,'"',
      '}\n',
      'end\n'
    ),sep="")
  }
);
Storm$methods(
  emit = function(tuple=Tuple) {
    t.prefix="[";
    t.suffix="]";
    #if (length(tuple$output) == 1) {
    # t.prefix="[";
    # t.suffix="]";
    #}
    a.prefix="[";
    a.suffix="]";
    #if (length(tuple$anchors) == 1) {
    # a.prefix="[";
    # a.suffix="]";
    #}
    cat(c(
      '{',
      '"command": "emit", ',
      
      #TODO enable reliable tuples, see
      #https://github.com/nathanmarz/storm/wiki/Guaranteeing-message-processing
      #'"id": "',as.character(runif(1) * 2**64 - 1),'", ',
      
      #TODO enable multi-anchoring, see:
      #https://github.com/nathanmarz/storm/wiki/Guaranteeing-message-processing
      '"anchors": ',a.prefix,toJSON(tuple$id),a.suffix,', ',

      #TODO enable id of stream tuple is emitted to, see:
      #https://github.com/nathanmarz/storm/wiki/Multilang-protocol
      #'"stream": "',tuple$stream,'", ',

      #TODO enable "emit direct", see:
      #https://github.com/nathanmarz/storm/wiki/Multilang-protocol
      #'"task": "',tuple$task,'", ',

      '"tuple": ',t.prefix,toJSON(tuple$output),t.suffix,
      '}\n',
      'end\n'
    ),sep="");
  }
);
#create a Storm object
storm = Storm$new();
#by default it has a handler that logs that the tuple was skipped.
#let's replace it that with something more useful:
storm$lambda = function(s) {
                                        #argument 's' is the Storm object.

                                        #get the current Tuple object.
    t = s$tuple;

                                        #optional: acknowledge receipt of the tuple.


                                        #optional: log a message.
    
    s$log(c("processing tuple=",t$id))
    s$log(c("processing tuple=",t$input))
    inputl = strsplit(as.character(t$input), ":")
    s$log(c("processing tuple=", length(inputl)))
    s$log(c("processing tuple=", inputl[[3]]))

    #s$ack(t);
                                        #create contrived tuples to illustrate output.

                                        #create 1st tuple...
    if ( length(inputl) == 3 ) {
        t$output = vector(mode="character",length=2);
        t$output[1] = as.numeric(inputl[[1]])
        t$output[2] = as.numeric(inputl[[3]])
                                        #t$output[1] = as.numeric(t$input[3])+as.numeric(t$input[4]);
                                        #...and emit it.
        s$emit(t);
    }
    s$ack(t);                                        #create 2nd tuple...
    #t$output[1] = as.numeric(t$input[3])-as.numeric(t$input[4]);
                                        #...and emit it.
    #s$emit(t);

                                        #alternative/optional: mark the tuple as failed.
    #s$fail(t);
};

#enter the main tuple-processing loop.
storm$run();