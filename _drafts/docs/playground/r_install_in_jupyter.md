
R Install In Jupyter  
==

이 문서는 Jupyter에 R을 설치하여 Jupyter에서 R을 함께 사용할 수 있도록 
R을 설치하는 절차를 설명한다.  

## 1. R, IRkernel Install  
conda를 이용해 R v3.6.0을 설치 시 7시간 정도가 소요되며, 
정상적으로 설치된다는 보장이 없다.  

다음은 소스를 직접 다운 받아 설치하는 절차이다.     

- 다운로드  
		# wget https://anaconda.org/r/r/3.6.0/download/linux-64/r-3.6.0-r36_0.tar.bz2
		# wget https://anaconda.org/r/r-base/3.6.0/download/linux-64/r-base-3.6.0-hce969dd_0.tar.bz2
		# wget https://anaconda.org/r/r-essentials/3.6.0/download/linux-64/r-essentials-3.6.0-r36_0.tar.bz2

- 설치  
		# conda install --offline r-3.6.0-r36_0.tar.bz2
		# conda install --offline r-base-3.6.0-hce969dd_0.tar.bz2
		# conda install --offline r-essentials-3.6.0-r36_0.tar.bz2

## 2. Prerequirement  

1. GCC  
	CentOS 7.6( Kernel 3.10 ) 이미지의 GCC 버전은 4.8.5로 C++ 11을 지원하고, C++14를 지원하지 않는다. 따라서 C++14를 
	이용하는 패키지(ex : rstan, prophet, streamR 등 ) 설치를 위해서 보다 상위 버전의 GCC가 필요하다.
	이 문서에서는 GCC 4.9.4 버전을 설치하고 설정한다.

	*모든 과정은 컨테이너 내부에서의 과정이다.*

	- bzip2 설치  
	  prerequisites pkg 설치를 진행하기 위해 bzip2가 설치되어 있지 않다면 설치를 진행한다.
			# yum install bzip2   

	- 소스 다운로드  
	  다른 버전을 사용하기 원한다면 gcc 오피셜 사이트에서 원하는 소스를 다운 받고 다음 과정을 그에 맞게 진행하면 된다.
			#wget http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-4.9.4/gcc-4.9.4.tar.gz

	- 압축 해제  
			# tar xf gcc-4.9.4.tar.gz
			# ls
			gcc-4.9.4

	- prerequisites 실행  
			# cd gcc-4.9.4
			# ./contrib/download_prerequisites

	- 빌드 디렉토리를 외부에 설정  
	  소스 코드와 빌드한 파일을 분리하여 관리하기 위해 빌드 디렉토리를 외부에 설정
			# cd ../
			# mkdir gcc-build
	  디렉토리는 다음과 같다.
			# ls
			gcc-build   gcc-4.9.4
	  빌드 디렉토리로 이동한다.
			# cd gcc-build
	  
	- prefix 설정  
	  R studio에 마운트되는 공용 라이브러리 디렉토리에 GCC 4.9.4 가 설치 될 수 있도록 설정한다.
			# ../gcc-4.9.4/configure --enable-languages=c,c++ --disable-multilib

	- 빌드  
	  -j 옵션 뒤의 숫자는 병렬 컴파일을 수행할 CPU의 수 이다. 빌드하는 시스템의 CPU에 맞게 조절한다.
			# make -j 4 

	- 설치
			# make install

	- R config 설정  
	  기존에 사용되던 GCC가 아닌 GCC-4.9.4 사용을 위해 다음의 config 파일들을 수정한다.  
			
			# cd /opt/conda/lib/R/etc/

		- ldpaths  
	       ldpaths 파일에 다음 내용을 추가한다.  
				# For GCC_4.9.4
				: ${GCC_4_9_4_LD_LIBRARY_PATH=/usr/local/lib}
				if test -n "${GCC_4_9_4_LD_LIBRARY_PATH}"; then
				  R_LD_LIBRARY_PATH="${R_LD_LIBRARY_PATH}:${GCC_4_9_4_LD_LIBRARY_PATH}"
				fi
				
		- Makeconf 
				
				CXX14 = /usr/local/bin/g++ -m64
				CXX14FLAGS =  $(LTO) -std=gnu++14 -fPIC -O2 -g
				CXX14PICFLAGS =
				CXX14STD = -std=gnu++14

2. Java 설정  
    - R java path 설정  
      설치되어 있는 java 를 확인하고 java path 설정한다.
            # vi /opt/conda/lib/R/etc/javaconf   
           
			: ${JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk}  
			: ${JAVA_CPPFLAGS=-I/usr/lib/jvm/java-1.8.0-openjdk/include -I/usr/lib/jvm/java-1.8.0-openjdk/include/linux}  
			: ${JAVA_LD_LIBRARY_PATH=/usr/lib/jvm/java-1.8.0-openjdk/jre/lib/amd64/server}  
			: ${JAVA_LIBS=~autodetect~}  
        javareconf 실행  
            # R CMD javareconf  
    - JVM 라이브러리 경로 설정  
        R의 ldpath 설정만으로 rJava 패키지 설치가 진행되지 않음.  
            # export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/jvm/java-1.8.0-openjdk/jre/lib/amd64/server  
             
        시스템에 고정으로 설정될 수 있도록 ld.so.conf 에 libjvm.so 파일의 경로를 추가한다.  
            # cd /etc/ld.so.conf.d/
            # cat > java.conf
            /usr/lib/jvm/java-1.8.0-openjdk/jre/lib/amd64/server
            crtl+d

3. openssl 1.1 설치  
    yum으로 설치한 openssl_1.0 사용 시 R 내부 패키지 openssl 설치 실패 발생  
    이로 인해 다른 패키지를 설치할 수 없음.  
    ( OPENSSL_init_ssl 을 할 수 없는 오류 발생 )  
    openssl 1.1 파일 다운로드
        # wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
        # tar xf openssl-1.1.1d.tar.gz
        # cd openssl-1.1.1d
        # ./config
        # make
        # make install

4. epel-release repo 설치  
        # yum install epel-release -y  

5. config 설정
    단락 3과 Annex B를 참고하여 /opt/conda/lib/R/etc 내에 있는 config 파일을 수정한다.

6. Jupyter notebook - R 연결
    Jupyter notebook 과 R 연결을 위해 R을 실행하고 최소 필요한 패키지를 설치하고 연결한다.  
    - R 실행  
            # R
    - IRKernel, IRdisplay 설치
            # install.packages(c('IRdisplay', 'IRkernel') )  
            # IRkernel::installspec()  
    - 웹에서 R kernel 실행 및 확인  
        웹 상에서 Newfile 에서 R이 추가된 것을 확인.  
        R를 이용해 Newfile을 생성 시 code 창 우측에 RO로 표시되어야 한다.  
        R 우측의 동그라미가 색이 채워져 있는 경우 오류이다.   

## 3. R config 설정  
- Makeconf
    수동으로 설치한 R의 경우 Makeconf 가 엉망으로 설정되어 있다.  
    아래 첨부된 Makeconf를 이용해 Makeconf를 재 설정한다.  
    경로와 같은 부분은 다른 부분이 있을 수 있으므로 필히 확인하고 진행한다.  
- javaconf  
    위에서 이미 설정에 대해서 설명하였으므로 설정에 대한 내용은 생략한다.  
    위 명령을 실행 시 오류가 없으면 java 설정은 완료된 것이다.  
        # R CMD javareconf            

## 4. R Package Install  
R 패키지 설치 문서 참고  

## Annex A ( troubleshooting )

- openssl(R Pkg) 설치 실패 
		# wget https://cran.r-project.org/src/contrib/openssl_1.4.1.tar.gz
		# R CMD INSTALL openssl_1.4.1.tar.gz --configure-vars='INCLUDE_DIR=/usr/local/include LIB_DIR=/usr/local/lib
	
- cannot find sql..
		#yum install postgresql-devel -y
- cannot find -lz  
		# yum -y install zlib*   
- make: gfortran: Command not found  
		# yum install gcc-gfortran -y   
- v8-devel   
		# yum install -y v8-devel  
- librsvg2  
		# yum install -y librsvg2-devel    
- configure: error: "libxml not found"   
		# yum install -y libxml2-devel  
- missing required header GL/glu.h  
		# yum install -y mesa-libGLU-devel  
- rJava : cannot find -lbz2  
		# yum install -y bzip2-devel  
- rJava : cannot find -licuuc  
		# yum install -y libicu-devel  
- rJava : cannot find -licui18n
		# yum install -y libicu-devel  
- magick : catnot find ImageMagick-c++-devel  
		# yum install -y ImageMagick-c++-devel  
- topicmodels : gsl/gsl_rng.h: No such file or directory
		# yum install -y gsl-devel
- av : cannot find ffmpeg
		# yum-config-manager --add-repo https://negativo17.org/repos/epel-multimedia.repo
		# yum install -y ffmpeg ffmpeg-devel  
- pdftool : cannot find lpoppler-cpp  
		# yum install -y poppler-cpp-devel    
- gifski : cannot find cargo  
		# yum install -y cargo    
- webp : cannot find lwebp  
		# yum install -y libwebp-devel  
- cannot find proj  
		# yum install -y proj-devel  
- cannot find gtk+2.0
		# yum install -y gtk2-devel
- cannot find ODBC driver
		# yum install -y unixODBC unixODBC-devel  
- cannot find ggobi >= 2.1.6  
	rggobi 설치를 위한 ggobi 설치와 rggobi 설치 시 옵션 설정 설명  
		# wget http://www.ggobi.org/downloads/ggobi-2.1.11.tar.bz2  
		# tar xf ggobi-2.1.11.tar.bz2   
		# cd ggobi-2.1.11   
		# ./configure --with-all-plugins  
		# make 
		# make install  
		# mkdir -p /etc/xdg/ggobi 
		# cp ggobirc /etc/xdg/ggobi/ggobirc
		# ln -s /usr/local/lib/libggobi.so.0 /usr/lib64/libggobi.so.0
		# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
		# R
		> install.packages("rggobi", \
		configure.vars='GGOBI_CFLAGS="-I/usr/local/include/ggobi \
		-I/usr/lib64/glib-2.0/include -I/usr/include/glib-2.0 \
		-I/usr/include/gtk-2.0 -I/usr/lib64/gtk-2.0/include \
		-I/usr/include/cairo -I/usr/include/pango-1.0 \
		-I/usr/include/gdk-pixbuf-2.0 -I/usr/include/atk-1.0 \
		-I/usr/include/libxml2" GGOBI_LIBS="-L/usr/local/lib -lggobi')
        

## Annex B ( config files )

- Makeconfig 
		include $(R_SHARE_DIR)/make/vars.mk

		AR = ar
		BLAS_LIBS = -L"$(R_HOME)/lib$(R_ARCH)" -lRblas
		C_VISIBILITY = -fvisibility=hidden
		CC = gcc -m64 -std=gnu99
		CFLAGS = -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic $(LTO)
		CPPFLAGS = -DNDEBUG -D_FORTIFY_SOURCE=2 -O2  -I/opt/conda/include -Wl,-rpath-link,/opt/conda/lib
		CPICFLAGS = -fpic
		CXX = g++ -m64 -std=gnu++11
		CXXCPP = $(CXX) -E
		CXXFLAGS = -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches   -m64 -mtune=generic $(LTO)
		CXXPICFLAGS = -fpic
		CXX98 = g++ -m64
		CXX98FLAGS = -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches   -m64 -mtune=generic $(LTO)
		CXX98PICFLAGS = -fpic
		CXX98STD = -std=gnu++98
		CXX11 = g++ -m64
		CXX11FLAGS = -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches   -m64 -mtune=generic $(LTO)
		CXX11PICFLAGS = -fpic
		CXX11STD = -std=gnu++11
		CXX14 = /usr/local/bin/g++ -m64
		CXX14FLAGS =  $(LTO) -std=gnu++14 -fPIC -O2 -g
		CXX14PICFLAGS =
		CXX14STD = -std=gnu++14
		CXX17 =
		CXX17FLAGS =  $(LTO)
		CXX17PICFLAGS =
		CXX17STD =


		DYLIB_EXT = .so
		DYLIB_LD = $(CC)
		DYLIB_LDFLAGS = -shared -fopenmp# $(CFLAGS) $(CPICFLAGS)
		DYLIB_LINK = $(DYLIB_LD) $(DYLIB_LDFLAGS) $(LDFLAGS)
		ECHO = echo
		ECHO_C = 
		ECHO_N = -n
		ECHO_T = 
		F_VISIBILITY = -fvisibility=hidden
		## FC is the compiler used for all Fortran as from R 3.6.0
		FC = gfortran
		FCFLAGS = -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -I/opt/conda/include -mtune=generic $(LTO)
		## additional libs needed when linking with $(FC), e.g. on some Oracle compilers
		FCLIBS_XTRA = 
		FFLAGS = -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches   -m64 -mtune=generic -I/opt/conda/include $(LTO)
		FLIBS =  -lgfortran -lm -lgomp -lquadmath -lpthread
		FPICFLAGS = -fpic
		FOUNDATION_CPPFLAGS = 
		FOUNDATION_LIBS = 
		JAR = /usr/local/java/jdk1.8.0_221/bin/jar
		JAVA = /usr/local/java/jdk1.8.0_221/bin/java
		JAVAC = /usr/local/java/jdk1.8.0_221/bin/javac
		JAVAH = /usr/local/java/jdk1.8.0_221/bin/javah
		## JAVA_HOME might be used in the next three.  
		## They are for packages 'JavaGD' and 'rJava'
		JAVA_HOME = /usr/local/java/jdk1.8.0_221
		JAVA_CPPFLAGS = -I/usr/local/java/jdk1.8.0_221/include -I/usr/local/java/jdk1.8.0_221/include/linux
		JAVA_LIBS = -L$(JAVA_HOME)/jre/lib/amd64/server -ljvm
		JAVA_LD_LIBRARY_PATH = /usr/local/java/jdk1.8.0_221/jre/lib/amd64/server
		LAPACK_LIBS = -L"$(R_HOME)/lib$(R_ARCH)" -lRlapack
		##LDFLAGS = -Wl,-O2 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,--disable-new-dtags -Wl,--gc-sections -Wl,-rpath,/opt/conda/lib -Wl,-rpath-link,/opt/conda/lib -L/opt/conda/lib -Wl,-rpath-link,/opt/conda/lib
		LDFLAGS = -Wl,-z,relro 

		## we only need this is if it is external, as otherwise link to R
		LIBINTL= 
		LIBM = -lm
		LIBR0 = -L"$(R_HOME)/lib$(R_ARCH)"
		LIBR1 = -lR
		LIBR = -L"$(R_HOME)/lib$(R_ARCH)" -lR
		LIBS =  -lpcre -llzma -lbz2 -lz -lrt -ldl -lm -licuuc -licui18n
		## needed by R CMD config
		LIBnn = lib
		LIBTOOL = $(SHELL) "$(R_HOME)/bin/libtool"
		LTO = 
		## needed to build applications linking to static libR
		MAIN_LD = $(CC)
		MAIN_LDFLAGS = -Wl,--export-dynamic -fopenmp
		RPATH_LDFLAGS = -Wl,-rpath,$(abs_top_builddir)/lib -Wl,-rpath,/opt/conda/lib
		MAIN_LINK = $(MAIN_LD) $(MAIN_LDFLAGS) $(LDFLAGS) $(RPATH_LDFLAGS)
		MKINSTALLDIRS = "$(R_HOME)/bin/mkinstalldirs"
		OBJC = gcc
		OBJCFLAGS = -g -O2 -fobjc-exceptions $(LTO)
		OBJC_LIBS =  
		OBJCXX = 
		R_ARCH = 
		RANLIB = ranlib
		SAFE_FFLAGS = -fopenmp -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -O2 -ffunction-sections -pipe -I/opt/conda/include -fdebug-prefix-map=/home/builder/ktietz/conda/conda-bld/r-base_1558084822424/work=/usr/local/src/conda/r-base-3.6.0 -fdebug-prefix-map=/opt/conda=/usr/local/src/conda-prefix -msse2 -mfpmath=sse
		SED = /bin/sed
		SHELL = /bin/bash
		SHLIB_CFLAGS = 
		SHLIB_CXXFLAGS = 
		SHLIB_CXXLD = $(CXX)
		SHLIB_CXXLDFLAGS = -shared
		SHLIB_CXX98LD = $(CXX98) $(CXX98STD)
		SHLIB_CXX98LDFLAGS = -shared
		SHLIB_CXX11LD = $(CXX11) $(CXX11STD)
		SHLIB_CXX11LDFLAGS = -shared
		SHLIB_CXX14LD = $(CXX14) $(CXX14STD)
		SHLIB_CXX14LDFLAGS = -shared
		SHLIB_CXX17LD = $(CXX17) $(CXX17STD)
		SHLIB_CXX17LDFLAGS = -shared
		SHLIB_EXT = .so
		SHLIB_FFLAGS = 
		SHLIB_LD = $(CC)
		SHLIB_LDFLAGS = -shared# $(CFLAGS) $(CPICFLAGS)
		SHLIB_LIBADD = 
		## We want to ensure libR is picked up from $(R_HOME)/lib
		## before e.g. /usr/local/lib if a version is already installed.
		SHLIB_LINK = $(SHLIB_LD) $(SHLIB_LDFLAGS) $(LIBR0) $(LDFLAGS)
		SHLIB_OPENMP_CFLAGS = -fopenmp
		SHLIB_OPENMP_CXXFLAGS = -fopenmp
		SHLIB_OPENMP_FFLAGS = 
		STRIP_STATIC_LIB = strip --strip-debug
		STRIP_SHARED_LIB = strip --strip-unneeded
		TCLTK_CPPFLAGS = -I/opt/conda/include -I/opt/conda/include 
		TCLTK_LIBS = -L/opt/conda/lib -ltcl8.6 -L/opt/conda/lib -ltk8.6 -lX11
		YACC = yacc

		## Legacy settings:  no longer used by R as of 3.6.0
		## Setting FC often sets F77 (on Solaris make even if set)
		## so must follow FC in this file.
		F77 = gfortran
		FCPICFLAGS = -fpic
		F77_VISIBILITY = -fvisibility=hidden
		SHLIB_FCLD = $(FC)
		SHLIB_FCLDFLAGS = -shared
		SHLIB_OPENMP_FCFLAGS = 


		## for linking to libR.a
		STATIC_LIBR = # -Wl,--whole-archive "$(R_HOME)/lib$(R_ARCH)/libR.a" -Wl,--no-whole-archive $(BLAS_LIBS) $(FLIBS)  $(LIBINTL) -lreadline  $(LIBS)

		## These are recorded as macros for legacy use in packages
		## set on AIX, formerly for old glibc (-D__NO_MATH_INLINES)
		R_XTRA_CFLAGS = 
		##  was formerly set on HP-UX
		R_XTRA_CPPFLAGS =  -I"$(R_INCLUDE_DIR)" -DNDEBUG
		## currently unset
		R_XTRA_CXXFLAGS = 
		## currently unset
		R_XTRA_FFLAGS = 

		## SHLIB_CFLAGS SHLIB_CXXFLAGS SHLIB_FFLAGS are apparently currently unused
		## SHLIB_CXXFLAGS is undocumented, there is no SHLIB_FCFLAGS
		ALL_CFLAGS =  $(PKG_CFLAGS) $(CPICFLAGS) $(SHLIB_CFLAGS) $(CFLAGS)
		ALL_CPPFLAGS =  -I"$(R_INCLUDE_DIR)" -DNDEBUG $(PKG_CPPFLAGS) $(CLINK_CPPFLAGS) $(CPPFLAGS)
		ALL_CXXFLAGS =  $(PKG_CXXFLAGS) $(CXXPICFLAGS) $(SHLIB_CXXFLAGS) $(CXXFLAGS)
		ALL_OBJCFLAGS = $(PKG_OBJCFLAGS) $(CPICFLAGS) $(SHLIB_CFLAGS) $(OBJCFLAGS)
		ALL_OBJCXXFLAGS = $(PKG_OBJCXXFLAGS) $(CXXPICFLAGS) $(SHLIB_CXXFLAGS) $(OBJCXXFLAGS)
		ALL_FFLAGS =  $(PKG_FFLAGS) $(FPICFLAGS) $(SHLIB_FFLAGS) $(FFLAGS)
		## can be overridden by R CMD SHLIB
		P_FCFLAGS = $(PKG_FFLAGS)
		ALL_FCFLAGS =  $(P_FCFLAGS) $(FPICFLAGS) $(SHLIB_FFLAGS) $(FCFLAGS)
		## LIBR here as a couple of packages use this without SHLIB_LINK
		ALL_LIBS = $(PKG_LIBS) $(SHLIB_LIBADD) $(LIBR)# $(LIBINTL)

		.SUFFIXES:
		.SUFFIXES: .c .cc .cpp .d .f .f90 .f95 .m .mm .M .o

		.c.o:
			$(CC) $(ALL_CPPFLAGS) $(ALL_CFLAGS) -c $< -o $@
		.c.d:
			@echo "making $@ from $<"
			@$(CC) -MM $(ALL_CPPFLAGS) $< > $@
		.cc.o:
			$(CXX) $(ALL_CPPFLAGS) $(ALL_CXXFLAGS) -c $< -o $@
		.cpp.o:
			$(CXX) $(ALL_CPPFLAGS) $(ALL_CXXFLAGS) -c $< -o $@
		.cc.d:
			@echo "making $@ from $<"
			@$(CXX) -M $(ALL_CPPFLAGS) $< > $@
		.cpp.d:
			@echo "making $@ from $<"
			@$(CXX) -M $(ALL_CPPFLAGS) $< > $@
		.m.o:
			$(OBJC) $(ALL_CPPFLAGS) $(ALL_OBJCFLAGS) -c $< -o $@
		.m.d:
			@echo "making $@ from $<"
			@gcc -MM $(ALL_CPPFLAGS) $< > $@
		.mm.o:
			$(OBJCXX) $(ALL_CPPFLAGS) $(ALL_OBJCXXFLAGS) -c $< -o $@
		.M.o:
			$(OBJCXX) $(ALL_CPPFLAGS) $(ALL_OBJCXXFLAGS) -c $< -o $@
		.f.o:
			$(FC) $(ALL_FFLAGS) -c $< -o $@
		## @FCFLAGS_f9x@ are flags needed to recognise the extensions
		.f95.o:
			$(FC) $(ALL_FCFLAGS) -c  $< -o $@
		.f90.o:
			$(FC) $(ALL_FCFLAGS) -c  $< -o $@


- javaconf  
		## Versions from settings when configure was run
		: ${JAVA_HOME=/usr/local/java/jdk1.8.0_221}
		: ${JAVA_CPPFLAGS=-I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux}
		: ${JAVA_LD_LIBRARY_PATH=${JAVA_HOME}/jre/lib/amd64/server}
		: ${JAVA_LIBS=~autodetect~}
		: ${JAVA=${JAVA_HOME}/bin/java}
		: ${JAVAC=${JAVA_HOME}/bin/javac}
		: ${JAVAH=${JAVA_HOME}/bin/javah}
		: ${JAR=${JAVA_HOME}/bin/jar}

- Renviron  
		### etc/Renviron.  Generated from Renviron.in by configure.
		###
		### ${R_HOME}/etc/Renviron
		###
		### Record R system environment variables.

		R_PLATFORM=${R_PLATFORM-'x86_64-conda_cos6-linux-gnu'}
		## Default printer paper size: first record if user set R_PAPERSIZE
		R_PAPERSIZE_USER=${R_PAPERSIZE}
		R_PAPERSIZE=${R_PAPERSIZE-'a4'}
		## Default print command
		R_PRINTCMD=${R_PRINTCMD-''}
		# for Rd2pdf, reference manual
		R_RD4PDF=${R_RD4PDF-'times,hyper'}
		## used for options("texi2dvi")
		R_TEXI2DVICMD=${R_TEXI2DVICMD-${TEXI2DVI-'texi2dvi'}}
		## used by untar(support_old_tars = TRUE) and installing grDevices
		R_GZIPCMD=${R_GZIPCMD-'/bin/gzip'}
		## Default zip/unzip commands
		R_UNZIPCMD=${R_UNZIPCMD-'/usr/bin/unzip'}
		R_ZIPCMD=${R_ZIPCMD-''}
		R_BZIPCMD=${R_BZIPCMD-'/opt/conda/bin/bzip2'}
		## Default browser
		R_BROWSER=${R_BROWSER-'/bin/open'}
		## Default editor
		EDITOR=${EDITOR-${VISUAL-vi}}
		## Default pager
		PAGER=${PAGER-'/usr/bin/less'}
		## Default PDF viewer
		R_PDFVIEWER=${R_PDFVIEWER-'/bin/open'}
		## Used by libtool
		LN_S='ln -s'
		MAKE=${MAKE-'make'}
		## Prefer a POSIX-compliant sed on e.g. Solaris
		SED=${SED-'/bin/sed'}
		## Prefer a tar that can automagically read compressed archives
		TAR=${TAR-'/bin/tar'}

		## System and compiler types.
		R_SYSTEM_ABI='linux,gcc,gxx,gfortran,gfortran'

		## Strip shared objects and static libraries.
		R_STRIP_SHARED_LIB=${R_STRIP_SHARED_LIB-'strip --strip-unneeded'}
		R_STRIP_STATIC_LIB=${R_STRIP_STATIC_LIB-'strip --strip-debug'}

		R_LIBS_USER=${R_LIBS_USER-'~/R/x86_64-conda_cos6-linux-gnu-library/3.6'}
		#R_LIBS_USER=${R_LIBS_USER-'~/Library/R/3.6/library'}

		### Local Variables: ***
		### mode: sh ***
		### sh-indentation: 2 ***
		### End: ***

- ldpath
		# https://github.com/conda/conda/issues/1679:
		#  Internally R_system() calls system() which
		# uses /bin/sh to launch various programs. If
		# /bin/sh is called with LD_LIBRARY_PATH that
		# loads condas shared libraries things break.
		#  It may be that not setting LD_LIBRARY_PATH
		# causes other things to break, in which case
		# R_system() will need to be modified so that
		# it calls execve() with an environment which
		# has these modifications to LD_LIBRARY_PATH
		# removed which may be tricky to orchestrate
		if [ "$(uname -s)" = "Linux" ]; then
		  return 0
		fi
		: ${JAVA_HOME=/usr/local/java/jdk1.8.0_221}
		: ${R_JAVA_LD_LIBRARY_PATH=/usr/local/java/jdk1.8.0_221/jre/lib/amd64/server}
		if test -n "/opt/conda/lib"; then
		: ${R_LD_LIBRARY_PATH=${R_HOME}/lib:/opt/conda/lib}
		else
		: ${R_LD_LIBRARY_PATH=${R_HOME}/lib}
		fi
		if test -n "${R_JAVA_LD_LIBRARY_PATH}"; then
		  R_LD_LIBRARY_PATH="${R_LD_LIBRARY_PATH}:${R_JAVA_LD_LIBRARY_PATH}"
		fi

		# For GCC_4.9.4
		: ${GCC_4_9_4_LD_LIBRARY_PATH=/usr/local/lib}
		if test -n "${GCC_4_9_4_LD_LIBRARY_PATH}"; then
		  R_LD_LIBRARY_PATH="${R_LD_LIBRARY_PATH}:${GCC_4_9_4_LD_LIBRARY_PATH}"
		fi

		## This is DYLD_FALLBACK_LIBRARY_PATH on Darwin (macOS) and
		## LD_LIBRARY_PATH elsewhere.
		## However, on macOS >=10.11 (if SIP is enabled, the default), the
		## environment value will not be passed to a script such as R.sh, so
		## would not seen here.
		if test -z "${LD_LIBRARY_PATH}"; then
		  LD_LIBRARY_PATH="${R_LD_LIBRARY_PATH}"
		else
		  LD_LIBRARY_PATH="${R_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}"
		fi
		export LD_LIBRARY_PATH
