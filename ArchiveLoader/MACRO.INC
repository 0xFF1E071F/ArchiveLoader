macro _invoke proc,[arg]
       { 
        common 
        stdcall [proc],arg 
       } 



struc db [data]
       {
         common
         label .data byte
         db data
         .size = $-1-.data
       }



struc rb [data]
       {
         common
         label .data byte
         rb data
         .size = $-.data
       } 