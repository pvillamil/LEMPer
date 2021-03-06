#!/usr/bin/env bash

# ImageMagick Installer
# Min. Requirement  : GNU/Linux Ubuntu 14.04
# Last Build        : 02/11/2019
# Author            : ESLabs.ID (eslabs.id@gmail.com)
# Since Version     : 1.0.0

# Include helper functions.
if [ "$(type -t run)" != "function" ]; then
    BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
    # shellchechk source=scripts/helper.sh
    # shellcheck disable=SC1090
    . "${BASEDIR}/helper.sh"
fi

# Make sure only root can run this installer script.
requires_root

function init_imagemagick_install() {
    local SELECTED_INSTALLER=""

    if "${AUTO_INSTALL}"; then
        if [[ -z "${PHP_IMAGEMAGICK_INSTALLER}" || "${PHP_IMAGEMAGICK_INSTALLER}" == "none" ]]; then
            INSTALL_IMAGEMAGICK="n"
        else
            INSTALL_IMAGEMAGICK="y"
            SELECTED_INSTALLER=${PHP_IMAGEMAGICK_INSTALLER}
        fi
    else
        while [[ "${INSTALL_IMAGEMAGICK}" != "y" && "${INSTALL_IMAGEMAGICK}" != "n" ]]; do
            read -rp "Do you want to install ImageMagick library? [y/n]: " -i y -e INSTALL_IMAGEMAGICK
        done
        echo ""
    fi

    if [[ "${INSTALL_IMAGEMAGICK}" == Y* || "${INSTALL_IMAGEMAGICK}" == y* ]]; then
        echo "Available ImageMagick installation method:"
        echo "  1). Install from Repository (repo)"
        echo "  2). Compile from Source (source)"
        echo "--------------------------------"

        while [[ ${SELECTED_INSTALLER} != "1" && ${SELECTED_INSTALLER} != "2" && ${SELECTED_INSTALLER} != "none" && \
            ${SELECTED_INSTALLER} != "repo" && ${SELECTED_INSTALLER} != "source" ]]; do
            read -rp "Select an option [1-2]: " -e SELECTED_INSTALLER
        done

        case ${SELECTED_INSTALLER} in
            1|"repo")
                echo "Installing ImageMagick library from repository..."
                run apt-get -qq install -y imagemagick
            ;;
            2|"source")
                echo "Installing ImageMagick library from source..."
                local CURRENT_DIR && \
                CURRENT_DIR=$(pwd)
                run cd "${BUILD_DIR}"
                run wget -q https://www.imagemagick.org/download/ImageMagick.tar.gz
                run tar -zxf ImageMagick.tar.gz
                run cd ImageMagick-*
                run ./configure
                run make
                run make install
                run ldconfig /usr/local/lib
                #run cd ../
                #run rm -fr ImageMagick-*
                run cd "${CURRENT_DIR}"
            ;;

            *)
                # Skip installation.
                error "Installer method not supported. ImageMagick installation skipped."
            ;;
        esac

        echo "Installing PHP Imagick extensions..."
        run apt-get -qq install -y php-imagick

        if "${DRYRUN}"; then
            warning "ImageMagick installed in dryrun mode."
        else
            if [[ -n $(command -v magick) ]]; then
                status "ImageMagick version $(magick -version | grep ^Version | cut -d' ' -f3) has been installed."
            elif [[ -n $(command -v identify) ]]; then
                status "ImageMagick version $(identify -version | grep ^Version | cut -d' ' -f3) has been installed."
            fi
        fi
    else
        warning "ImageMagick installation skipped..."
    fi
}

echo "[ImageMagick Packages Installation]"

# Start running things from a call at the end so if this script is executed
# after a partial download it doesn't do anything.
if [[ -n $(command -v magick) || -n $(command -v identify) ]]; then
    warning "ImageMagick already exists. Installation skipped..."
else
    init_imagemagick_install "$@"
fi
