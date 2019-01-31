       copy "windows".
       identification division.
       program-id. davsstack.
      ******************************************************************
      *  Stack Size Calculator
      *  Show how you can use some Windows API calls to work out the
      *  current stack size.
      *  
      *  Demo is recursize with a "local-storage section". This is
      *  allocated on the stack when run as native code in Micro Focus.
      *  
      *  Date - 31/01/2019
      *  
      ******************************************************************
       environment division.
       special-names.
           call-convention 74 is winapi.

       data division.
       working-storage section.
       01  ws-stack-depth        pic 9(10) value 0.
       01  ws-teb-ptr            pointer.
       01  ws-stack-size         pic 9(9) comp-5.
       01  ws-mbi                MEMORY-BASIC-INFORMATION.
       01  ws-size-in            SIZE-T.
       01  ws-size-out           SIZE-T.
       01  ws-ptr                pointer.
       01  ws-ptr9               pic 9(9) comp-5 redefines ws-ptr.

       thread-local-storage section.

       local-storage section.
       01  ws-local              pic x(1024).

       linkage section.
       01  lnk-teb.
           03  lnk-seh           pointer.
           03  lnk-stackbase     pic 9(9) comp-5.
           03  lnk-stacklimit    pic 9(9) comp-5.

       procedure division.

      *    if ws-stack-depth = 0
               perform check-stack-size
      *    end-if

           add 1 to ws-stack-depth
           display "Current Stack Depth=" ws-stack-depth
           set ws-ptr to address of ws-local
           compute ws-stack-size = lnk-stackbase - ws-ptr9
           display "Stack Usage = " ws-stack-size
           move all "A" to ws-local
           call "davsstack"

           goback.

       check-stack-size section.

           call winapi "NtCurrentTeb" returning ws-teb-ptr
           set address lnk-teb to ws-teb-ptr
           compute ws-stack-size = lnk-stackbase - lnk-stacklimit
           display "Stack Size from Thread Environment Block = "
                     ws-stack-size

           move length of ws-mbi to ws-size-in
           call winapi "VirtualQuery" using by value lnk-stacklimit
                                            by reference ws-mbi
                                            by value ws-size-in
               returning ws-size-out
           end-call
           display "StackRegion Size from VirtualQuery = "
               regionsize of ws-mbi 
           .
