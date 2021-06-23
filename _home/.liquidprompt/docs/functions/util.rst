Utility Functions
*****************

These functions are designed to be used by themes.

.. function:: _lp_as_text(string) -> stdout

   Return *string* with all shell escaped substrings removed.

.. function:: _lp_bool(variable, [code])

   .. deprecated:: 2.0

   Stores the *code* in a variable named *variable*. If *code* is not set, uses
   the last return code instead.

.. function:: _lp_color_map(value, scale=100) -> var:ret

   Returns a color from the configured or default color map based on *value*
   and optional *scale*.

   Values below 0 or above *scale* will be capped.

   The returned string is a fully escaped terminal formatting sequence.

.. function:: _lp_sb(string) -> stdout

   .. deprecated:: 2.0
      Use the return code of the source data function to determine if any
      string was returned.

   If *string* is set and not empty, returns *string* padded with an extra space
   on the right and the left.

.. function:: _lp_sl(string) -> stdout

   .. deprecated:: 2.0
      Use the return code of the source data function to determine if any
      string was returned.

   If *string* is set and not empty, returns *string* padded with an extra space
   on the left.

.. function:: _lp_sr(string) -> stdout

   .. deprecated:: 2.0
      Use the return code of the source data function to determine if any
      string was returned.

   If *string* is set and not empty, returns *string* padded with an extra space
   on the right.

.. function:: _lp_smart_mark([vcs_type]) -> var:lp_smart_mark

   Returns a string set to the configured mark matching *vcs_type*. If
   *vcs_type* is not set, uses the value of ``lp_vcs_type`` instead.

   If the type is "git", extra checks are done to see if the repository is of
   type VCSH or git-svn instead, and return their marks if so.

.. function:: _lp_title(title) -> stdout

   .. deprecated:: 2.0
      Use :attr:`_lp_formatted_title` instead.

   Formats *title* with title escape codes. The input is escaped using
   :func:`_lp_as_text` to strip terminal formatting from being added to the
   title. The output should be added to :envvar:`PS1` to be printed as a title.

   This function will do nothing if :attr:`LP_ENABLE_TITLE` is disabled.

.. function:: _lp_formatted_title(title)

   Sets the theme generated title to *title*. The input is escaped using
   :func:`_lp_as_text` to strip terminal formatting from being added to the
   title.

   This function will do nothing and return ``2`` if :attr:`LP_ENABLE_TITLE`
   is disabled.

   .. versionadded:: 2.0

.. function:: _lp_raw_title(title)

   Sets the theme generated title to *title*. The input is not escaped in any
   way: if the input contains terminal formatting, use :func:`_lp_title`
   instead.

   This function will do nothing and return ``2`` if :attr:`LP_ENABLE_TITLE`
   is disabled.

   .. versionadded:: 2.0

