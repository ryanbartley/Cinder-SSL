if( NOT TARGET Cinder-SSL )
	
	get_filename_component( CINDER_SSL_BLOCKS_PATH "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE )
  
  	if( NOT EXISTS ${CINDER_PATH} )
    		get_filename_component( CINDER_PATH "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE )
  	endif()

	if( NOT TARGET cinder )
		include( "${CINDER_PATH}/proj/cmake/configure.cmake" )
		find_package( cinder REQUIRED PATHS
			"${CINDER_PATH}/${CINDER_LIB_DIRECTORY}"
			"$ENV{CINDER_PATH}/${CINDER_LIB_DIRECTORY}" )
	endif()
		
	string( TOLOWER "${CINDER_TARGET}" CINDER_TARGET_LOWER )
	
	get_filename_component( SSL_LIBS_PATH "${CINDER_SSL_BLOCKS_PATH}/lib/${CINDER_TARGET_LOWER}" ABSOLUTE )
	get_filename_component( SSL_INCLUDE_PATH "${CINDER_SSL_BLOCKS_PATH}/include/${CINDER_TARGET_LOWER}/include" ABSOLUTE )
	set( Cinder-SSL_LIBRARIES ${SSL_LIBS_PATH}/libssl.a ${SSL_LIBS_PATH}/libcrypto.a )
	set( Cinder-SSL_INCLUDES ${SSL_INCLUDE_PATH} )

endif()
