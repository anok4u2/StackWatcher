       identification division.
       program-id. stackwatcher.
      ******************************************************************
      *  
      *  Author : D Sands (3rd Line Support Micro Focus)
      *  
      *  Stack Size Calculator
      *  
      *  Show how you can use some Windows API calls to work out the
      *  current stack size.
      *  
      *  Demo is recursive with a "local-storage section". This is
      *  allocated on the stack when run as native code in Micro Focus.
      *  
      *  The code should work in either 32 or 64bit. 
      *  
      *  Date - 11/02/2019
      *  
      ******************************************************************
       environment division.
       special-names.
           call-convention 74 is winapi.

       data division.
       working-storage section.
       01  ws-stack-depth        pic 9(10) value 0.
       01  ws-teb-ptr            pointer.
       01  ws-mbi.  *>  MEMORY-BASIC-INFORMATION.
        02 baseaddress           pointer.
        02 allocationbase        pointer.
      $if p64 set
        02 allocationprotect pic 9(18) comp-5.
        02 regionsize        pic 9(18) comp-5.
        02 state             pic 9(18) comp-5.
        02 protect           pic 9(18) comp-5.
        02 1type             pic 9(18) comp-5.
      $else
        02 allocationprotect pic 9(9) comp-5.
        02 regionsize        pic 9(9) comp-5.
        02 state             pic 9(9) comp-5.
        02 protect           pic 9(9) comp-5.
        02 1type             pic 9(9) comp-5.
      $end
      $if p64 set
       01  ws-size-in            pic 9(18) comp-5.
       01  ws-size-out           pic 9(18) comp-5.
       01  ws-stack-size         pic 9(18) comp-5.
       01  ws-lowLim             pic 9(18) comp-5.
       01  ws-HighLim            pic 9(18) comp-5.
      $else
       01  ws-stack-size         pic 9(9) comp-5.
       01  ws-size-in            pic 9(9) comp-5.
       01  ws-size-out           pic 9(9) comp-5.
       01  ws-lowLim             pic 9(9) comp-5.
       01  ws-HighLim            pic 9(9) comp-5.
      $end
       01  ws-ptr                pointer.
      $if p64 set
       01  ws-ptr9               pic 9(18) comp-5 redefines ws-ptr.
      $else
       01  ws-ptr9               pic 9(9) comp-5 redefines ws-ptr.
      $end
       01  ws-stacklimit         pic 9(9) comp-5.
       01  ws-stacklimitkb       pic 9(5).
       01  ws-stackpct           pic 9(3).

       thread-local-storage section.

       local-storage section.
       01  ls-local              pic x(1024).
       01  ls-end                pic x.

       linkage section.
       01  lnk-teb.
           03  lnk-seh           pointer.
      $if p64 set
           03  lnk-stackbase     pic 9(18) comp-5.
           03  lnk-stacklimit    pic 9(18) comp-5.
      $else 
           03  lnk-stackbase     pic 9(9) comp-5.
           03  lnk-stacklimit    pic 9(9) comp-5.
      $end

       procedure division.

           if ws-stack-depth = 0
               perform get-defined-stack
           end-if

      *    if ws-stack-depth = 0
               perform check-stack-size
      *    end-if

           add 1 to ws-stack-depth
           display "Current Stack Depth=" ws-stack-depth
           set ws-ptr to address of ls-end
           compute ws-stack-size = lnk-stackbase - ws-ptr9
           compute ws-stackpct = (ws-stack-size/ws-stacklimit) * 100
           display "Current stack usage is " ws-stackpct "%"
           if ws-stackpct > 90
               display "******* DANGER ******** : Using more than "
                       "90% of Stack"
           end-if
           display " "
           move all "A" to ls-local

      ***** Recursively call ourself to generate more local-storage
      ***** On the stack. 
      ***** We deliberatly are allowing this to run until it crashes.
      ***** Windows will eventually terminate this with a Stack 
      ***** Overflow.
           call "stackwatcher"

           goback.

       check-stack-size section.

      ***** The Current Thread Stack Limit and Base are held in the
      ***** Thread Environment Block. The Stack can grow up to the 
      ***** limit defined. So this Limit may not be hard until it
      ***** reaches the Actual HARD limit for the thread.

      ***** We have used GetCurrentThreadStackLimits to get the 
      ***** hard stack limit.

           call winapi "NtCurrentTeb" returning ws-teb-ptr
           set address lnk-teb to ws-teb-ptr
           compute ws-stack-size = lnk-stackbase - lnk-stacklimit
           display "Stack Size from Thread Environment Block = "
                     ws-stack-size

      ***** Virtual Query is alternative to find the size of the
      ***** Stack Currently
           move length of ws-mbi to ws-size-in
           call winapi "VirtualQuery" using by value lnk-stacklimit
                                            by reference ws-mbi
                                            by value ws-size-in
               returning ws-size-out
           end-call
           display "StackRegion Size from VirtualQuery = "
               regionsize of ws-mbi 
           .


       get-defined-stack section.
           
           call winapi "GetCurrentThreadStackLimits" using
                  by reference ws-lowLim ws-HighLim
           end-call
           subtract ws-lowLim from ws-HighLim giving ws-stacklimit
           display "Process Stack Limit = " ws-stacklimit " bytes"
           divide ws-stacklimit by 1024 giving ws-stacklimitkb
           display "Process Stack Limit = " ws-stacklimitkb " kb"
           display " "
           display " "
           display " "
           display " "
           .