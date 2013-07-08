##*****************************************************************************
#  AUTHOR:
#    Morris Jette <jette1@llnl.gov>
#
#  SYNOPSIS:
#    X_AC_CRAY
#
#  DESCRIPTION:
#    Test for Cray XT and XE systems with 2-D/3-D interconnects.
#    Tests for required libraries (Native Cray systems only):
#    * libjob
#    Tests for required libraries (ALPS Cray systems only):
#    * mySQL (relies on testing for mySQL presence earlier);
#    * libexpat, needed for XML-RPC calls to Cray's BASIL
#      (Batch Application  Scheduler Interface Layer) interface.
#*****************************************************************************

AC_DEFUN([X_AC_CRAY],
[
  ac_have_native_cray="no"
  ac_have_alps_cray="no"
  ac_have_real_cray="no"
  ac_have_alps_emulation="no"
  ac_have_alps_cray_emulation="no"

  AC_ARG_WITH(
    [alps-emulation],
    AS_HELP_STRING(--with-alps-emulation,Run SLURM against an emulated ALPS system - requires option cray.conf @<:@default=no@:>@),
    [test "$withval" = no || ac_have_alps_emulation=yes],
    [ac_have_alps_emulation=no])

  AC_ARG_ENABLE(
    [cray-emulation],
    AS_HELP_STRING(--enable-alps-cray-emulation,Run SLURM in an emulated Cray mode),
      [ case "$enableval" in
        yes) ac_have_alps_cray_emulation="yes" ;;
         no) ac_have_alps_cray_emulation="no"  ;;
          *) AC_MSG_ERROR([bad value "$enableval" for --enable-alps-cray-emulation])  ;;
      esac ]
  )

  AC_ARG_ENABLE(
    [native-cray],
    AS_HELP_STRING(--enable-native-cray,Run SLURM natively on a Cray),
      [ case "$enableval" in
        yes) ac_have_native_cray="yes" ;;
         no) ac_have_native_cray="no"  ;;
          *) AC_MSG_ERROR([bad value "$enableval" for --enable-native-cray])  ;;
      esac ]
  )

  if test "$ac_have_alps_emulation" = "yes"; then
    ac_have_alps_cray="yes"
    AC_MSG_NOTICE([Running A ALPS Cray system against an ALPS emulation])
    AC_DEFINE(HAVE_ALPS_EMULATION, 1, [Define to 1 if running against an ALPS emulation])
  elif test "$ac_have_alps_cray_emulation" = "yes"; then
    ac_have_alps_cray="yes"
    AC_MSG_NOTICE([Running in Cray emulation mode])
    AC_DEFINE(HAVE_ALPS_CRAY_EMULATION, 1, [Define to 1 for emulating a Cray XT/XE system using ALPS])
  elif test "$ac_have_native_cray" = "yes"; then
    ac_have_native_cray="yes"
    AC_MSG_NOTICE([Running on a Cray in native mode without ALPS])
    AC_DEFINE(HAVE_NATIVE_CRAY, 1, [Define to 1 for running on a Cray in native mode without ALPS])
    if test -f /etc/xtrelease || test -d /etc/opt/cray/release; then
      ac_have_real_cray="yes"
    fi
  else
    # Check for a Cray-specific file:
    #  * older XT systems use an /etc/xtrelease file
    #  * newer XT/XE systems use an /etc/opt/cray/release/xtrelease file
    #  * both have an /etc/xthostname
    AC_MSG_CHECKING([whether this is a native ALPS Cray XT or XE system or have ALPS simulator])

    if test -f /etc/xtrelease || test -d /etc/opt/cray/release; then
      ac_have_alps_cray="yes"
      ac_have_real_cray="yes"
    fi
    AC_MSG_RESULT([$ac_have_alps_cray])
  fi

  if test "$ac_have_real_cray" = "yes"; then
    AC_CHECK_LIB([job], [job_getjid], [],
            AC_MSG_ERROR([Need cray-job (usually in /opt/cray/job/default)]))
    AC_DEFINE(HAVE_REAL_CRAY, 1, [Define to 1 for running on a real Cray system])
  fi

  if test "$ac_have_alps_cray" = "yes"; then
    # libexpat is always required for the XML-RPC interface
    AC_CHECK_HEADER(expat.h, [],
                    AC_MSG_ERROR([Cray BASIL requires expat headers/rpm]))
    AC_CHECK_LIB(expat, XML_ParserCreate, [],
                 AC_MSG_ERROR([Cray BASIL requires libexpat.so (i.e. libexpat1-dev)]))

    if test -z "$MYSQL_CFLAGS" || test -z "$MYSQL_LIBS"; then
      AC_MSG_ERROR([Cray BASIL requires the cray-MySQL-devel-enterprise rpm])
    fi

    # Used by X_AC_DEBUG to set default SALLOC_RUN_FOREGROUND value to 1
    x_ac_salloc_background=no

    AC_DEFINE(HAVE_3D,           1, [Define to 1 if 3-dimensional architecture])
    AC_DEFINE(SYSTEM_DIMENSIONS, 3, [3-dimensional architecture])
    AC_DEFINE(HAVE_FRONT_END,    1, [Define to 1 if running slurmd on front-end only])
    AC_DEFINE(HAVE_ALPS_CRAY,         1, [Define to 1 for Cray XT/XE systems using ALPS])
    AC_DEFINE(SALLOC_KILL_CMD,   1, [Define to 1 for salloc to kill child processes at job termination])
  elif test "$ac_have_native_cray" = "yes"; then
    AC_CHECK_HEADER(job.h, [],
                    AC_MSG_ERROR([Cray job.h is needed to run in natvie mode]))
    AC_DEFINE(HAVE_3D,           1, [Define to 1 if 3-dimensional architecture])
    AC_DEFINE(SYSTEM_DIMENSIONS, 3, [3-dimensional architecture])
    AC_DEFINE(HAVE_NATIVE_CRAY,  1, [Define to 1 for Native Cray systems])
  fi
  AM_CONDITIONAL(HAVE_NATIVE_CRAY, test "$ac_have_native_cray" = "yes")
  AM_CONDITIONAL(HAVE_ALPS_CRAY, test "$ac_have_alps_cray" = "yes")
  AM_CONDITIONAL(HAVE_REAL_CRAY, test "$ac_have_real_cray" = "yes")
  AM_CONDITIONAL(HAVE_ALPS_EMULATION, test "$ac_have_alps_emulation" = "yes")
  AM_CONDITIONAL(HAVE_ALPS_CRAY_EMULATION, test "$ac_have_alps_cray_emulation" = "yes")
])
