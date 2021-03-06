cmake_minimum_required(VERSION 3.9.0)

project(CARLA)

if (WIN32)
else (WIN32)
include("Build/CMakeLists.txt.in")
endif (WIN32)

add_subdirectory("LibCarla/cmake")

# set(CMAKE_VERBOSE_MAKEFILE 1)  # debug helper

# message(${CMAKE_SOURCE_DIR})
set(INSTALL_FOLDER ${CMAKE_SOURCE_DIR}/Unreal/CarlaUE4/Plugins/Carla/CarlaServer)
set(CMAKE_INSTALL_PREFIX ${INSTALL_FOLDER})
set(PYTHON_CLIENT_FOLDER ${CMAKE_SOURCE_DIR}/PythonClient/test)
set(BASE_BUILD_FOLDER ${CMAKE_SOURCE_DIR}/Util/Build/carlaserver-build)
set(MY_CMAKE_FOLDER ${CMAKE_SOURCE_DIR}/Util/cmake)
# set(MY_CMAKE_FLAGS -B"$(BUILD_FOLDER)")

if (WIN32)
set(PROTOC_WIN32_COMMAND "cmd.exe" CACHE STRING command)
set(PROTOC_COMPILE " /k \"cd ${CMAKE_SOURCE_DIR} & cd Util & call Protoc.bat & exit\"" CACHE STRING command)
set(PROTOC_CLEAN " /k \"cd Util & call Protoc.bat --clean & exit\"" CACHE STRING command)
message(${PROTOC_WIN32_COMMAND})
message(${PROTOC_COMPILE})
else (WIN32)
set(PROTOC_WIN32_COMMAND "")
set(PROTOC_COMPILE "./Util/Protoc.sh")
set(PROTOC_CLEAN "./Util/Protoc.sh --clean")
endif (WIN32)

### Build ######################################################################

add_custom_target(protobuf
    DEPENDS build
    COMMAND ${PROTOC_WIN32_COMMAND}
    ARGS ${PROTOC_COMPILE}
)

### Docs #######################################################################

# docs: doxygen
FIND_PACKAGE(Doxygen)
IF(DOXYGEN_FOUND)
    # SET(DOXYGEN_CONF_FILE "doxygen")
    # SET(DOXYGEN_CONF_PATH ${CMAKE_CURRENT_BINARY_DIR}/${DOXYGEN_CONF_FILE})
    # SET(DOXYGEN_SOURCE_DIR ${CMAKE_SOURCE_DIR})
    # SET(DOXYGEN_TARGET "doc" )
    # 
    # CONFIGURE_FILE(${DOXYGEN_CONF_FILE}.in ${DOXYGEN_CONF_PATH})
    # 
    # ADD_CUSTOM_TARGET(${DOXYGEN_TARGET}
    #     ${DOXYGEN_EXECUTABLE} ${DOXYGEN_CONF_PATH}
    #     DEPENDS  ${DOXYGEN_CONF_PATH})
    #   FILE (READ ${CMAKE_SOURCE_DIR}/Doxyfile DOXYGEN_CONFIG_CONTENT )
    FILE (WRITE ${CMAKE_CURRENT_BINARY_DIR}/cmake-Doxyfile ${DOXYGEN_CONFIG_CONTENT} )
    FILE (APPEND ${CMAKE_CURRENT_BINARY_DIR}/cmake-Doxyfile "OUTPUT_DIRECTORY=${CMAKE_CURRENT_BINARY_DIR}/doc\n" )

    ADD_CUSTOM_TARGET ( doc
      ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/cmake-Doxyfile
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      COMMENT "Generating API documentation with Doxygen" VERBATIM
      )

    INSTALL ( CODE "EXECUTE_PROCESS(COMMAND \"${CMAKE_COMMAND}\" --build  \"${PROJECT_BINARY_DIR}\" --target doc)")
    INSTALL ( DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc/html DESTINATION docs)
ELSE(DOXYGEN_FOUND)
    # MESSAGE(WARNING "doxygen binary couldn't be found")
ENDIF(DOXYGEN_FOUND)

### Clean ######################################################################
# cmake --build . --config Release --target clean
# clean: $(CLEAN_RULE)
#   @$(PROTOC_CLEAN)
# 
# clean_linux:
#   @rm -Rf $(BASE_BUILD_FOLDER) $(INSTALL_FOLDER) Doxygen
# 
# clean_windows:
#   -@rd /s /q "$(BASE_BUILD_FOLDER)" "$(INSTALL_FOLDER)" Doxygen 2>nul
# add_custom_target(clean
#     # Win32
#     # COMMAND cmd.exe /k @$(PROTOC_CLEAN)
#     COMMAND $(PROTOC_CLEAN)
#     COMMAND ${CMAKE_COMMAND} -E REMOVE_RECURSE BASE_BUILD_FOLDER
#     COMMAND ${CMAKE_COMMAND} -E REMOVE_RECURSE ${INSTALL_FOLDER}
#     COMMAND ${CMAKE_COMMAND} -E REMOVE_RECURSE Doxygen
# )

### Test #######################################################################

add_custom_target(check
    DEPENDS debug launch_test_clients run_test_debug kill_test_clients
)

add_custom_target(check_release
    DEPENDS release launch_test_clients run_test_release kill_test_clients
)

add_custom_target(run_test_debug
    COMMAND @-LD_LIBRARY_PATH=$(INSTALL_FOLDER)/shared $(INSTALL_FOLDER)/bin/test_carlaserverd --gtest_shuffle $(GTEST_ARGS)
)

add_custom_target(run_test_release
    COMMAND @-LD_LIBRARY_PATH=$(INSTALL_FOLDER)/shared $(INSTALL_FOLDER)/bin/test_carlaserver --gtest_shuffle $(GTEST_ARGS)
)

add_custom_target(launch_test_clients
    COMMAND echo "Launch echo client"
    COMMAND python3 $(PYTHON_CLIENT_FOLDER)/test_client.py --echo -v -p 4000 --log echo_client.log & echo $$! > echo_client.pid
    COMMAND echo "Launch carla client"
    COMMAND python3 $(PYTHON_CLIENT_FOLDER)/test_client.py -v -p 2000 --log carla_client.log & echo $$! > carla_client.pid
)

add_custom_target(kill_test_clients
    COMMAND echo "Kill echo client"
    COMMAND kill `cat echo_client.pid` && rm echo_client.pid
    COMMAND echo "Kill carla client"
    COMMAND kill `cat carla_client.pid` && rm carla_client.pid
)

add_subdirectory("${CMAKE_SOURCE_DIR}/Util/cmake")
