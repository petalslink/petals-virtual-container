/**
 * Copyright (c) 2015-2016 Linagora
 * 
 * This program/library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or (at your
 * option) any later version.
 * 
 * This program/library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program/library; If not, see <http://www.gnu.org/licenses/>
 * for the GNU Lesser General Public License version 2.1.
 */
package org.ow2.petals.roboconf;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Properties;
import java.util.logging.Logger;

import com.ebmwebsourcing.easycommons.properties.PropertiesException;
import com.ebmwebsourcing.easycommons.properties.PropertiesHelper;

import net.roboconf.plugin.api.PluginException;

public class Utils {

    private Utils() {
        // Utility class, no constructor
    }

    /**
     * <p>
     * Resolve the file name of a JBI component properties file.
     * </p>
     * <p>
     * If the container name or the component name are used as placeholder (<code>${container-name}</code>,
     * <code>${component-name}</code> in the properties file name, they will be resolved.</code>
     * </p>
     * 
     * @param propertiesFileName
     *            The file name to resolve
     * @param containerName
     *            The container name that replaces its placeholder.
     * @param componentName
     *            The component name that replaces its placeholder.
     * @return
     * @throws PluginException
     */
    public static final String resolvePropertiesFileName(final String propertiesFileName, final String containerName,
            final String componentName) throws PluginException {

        try {
            if (propertiesFileName != null && !propertiesFileName.isEmpty()) {
                final Properties placeHolders = new Properties();
                placeHolders.setProperty("container-name", containerName);
                placeHolders.setProperty("component-name", componentName);
                return PropertiesHelper.resolveString(propertiesFileName, placeHolders);
            } else {
                return null;
            }
        } catch (final PropertiesException e) {
            throw new PluginException(e);
        }
    }

    /**
     * Store the properties file of a JBI component
     * 
     * @param properties
     *            The properties to store. Not <code>null</code>.
     * @param propertiesFile
     *            The file in which properties are stored Not <code>null</code>.
     * @param componentName
     *            The component name for which the properties file is stored Not <code>null</code>.
     * @param logger
     * @throws PluginException
     */
    public static final void storePropertiesFile(final Properties properties, final File propertiesFile,
            final String componentName, final Logger logger) throws PluginException {

        assert properties != null;
        assert propertiesFile != null;
        assert componentName != null;

        propertiesFile.getParentFile().mkdirs();
        try (final FileOutputStream fos = new FileOutputStream(propertiesFile)) {
            properties.store(fos,
                    "Don't update, this file is generated by Roboconf agent according to the Roboconf application dependencies");
        } catch (final FileNotFoundException e) {
            throw new PluginException(
                    String.format("The properties file '%s' of component '%s' can not be created or updated.",
                            propertiesFile.getAbsolutePath(), componentName),
                    e);
        } catch (final IOException e) {
            throw new PluginException(
                    String.format("An error occurs writing the properties file '%s' of component '%s'.",
                            propertiesFile.getAbsolutePath(), componentName),
                    e);
        }
    }

}
