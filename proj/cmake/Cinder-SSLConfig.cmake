if( NOT TARGET Cinder-SSL )
	
	get_filename_component( CINDER_SSL_INCLUDE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../lib" ABSOLUTE )
	get_filename_component( CINDER_PATH "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE )

	if( NOT TARGET cinder )
		include( "${CINDER_PATH}/proj/cmake/configure.cmake" )
		find_package( cinder REQUIRED PATHS
			"${CINDER_PATH}/${CINDER_LIB_DIRECTORY}"
			"$ENV{CINDER_PATH}/${CINDER_LIB_DIRECTORY}" )
	endif()
		
	string( TOLOWER "${CINDER_TARGET}" CINDER_TARGET_LOWER )
	
	get_filename_component( SSL_LIBS_PATH "${CMAKE_CURRENT_LIST_DIR}/../../lib/${CINDER_TARGET_LOWER}/${CMAKE_BUILD_TYPE}" ABSOLUTE )
	set( Cinder-SSL_LIBRARIES ${SSL_LIBS_PATH}/libcrypto.a ${SSL_LIBS_PATH}/libssl.a )
	set( Cinder-SSL_INCLUDES ${CINDER_SSL_INCLUDE_PATH}/include )

endif()
