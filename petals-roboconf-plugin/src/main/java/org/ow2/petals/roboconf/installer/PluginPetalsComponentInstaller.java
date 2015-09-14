/**
 * Copyright (c) 2015 Linagora
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
package org.ow2.petals.roboconf.installer;

import static org.ow2.petals.roboconf.Constants.COMPONENT_VARIABLE_NAME_PROPERTIESFILE;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_SU_COMPONENT;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.logging.Level;

import net.roboconf.core.model.beans.Import;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.beans.Instance.InstanceStatus;
import net.roboconf.plugin.api.PluginException;

import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;

import com.ebmwebsourcing.easycommons.properties.PropertiesException;
import com.ebmwebsourcing.easycommons.properties.PropertiesHelper;

public abstract class PluginPetalsComponentInstaller extends PluginPetalsJbiArtifactInstaller {

    public PluginPetalsComponentInstaller() throws DuplicatedServiceException, MissingServiceException {
        super();
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {
        // NOP: Hack to workaround https://github.com/roboconf/roboconf-platform/issues/331
        // TODO: Remove when https://github.com/roboconf/roboconf-platform/issues/331 will be fixed
    }

    @Override
    public void start(final Instance instance) throws PluginException {
        // NOP: Hack to workaround https://github.com/roboconf/roboconf-platform/issues/331
        // TODO: Remove when https://github.com/roboconf/roboconf-platform/issues/331 will be fixed
        super.deploy(instance);
        super.start(instance);
    }

    @Override
    protected Properties getConfigurationProperties(final Instance componentInstance) throws PluginException {

        // We generate the component properties file containing all configuration parameters of children service units
        final String propertiesFileName = this.getPropertiesFileName(componentInstance);
        if (propertiesFileName != null && !propertiesFileName.isEmpty()) {
            final File propertiesFile = new File(propertiesFileName);
            if (!propertiesFile.exists()
                    || (propertiesFile.exists() && propertiesFile.canWrite() && propertiesFile.isFile())) {

                if (!propertiesFile.getParentFile().exists()) {
                    if (!propertiesFile.getParentFile().mkdirs()) {
                        throw new PluginException(String.format(
                                "Unable to create parent directories of the properties file '%s' of component '%s'.",
                                propertiesFileName, componentInstance.getName()));
                    }
                }

                final Properties serviceUnitProperties = PluginPetalsComponentInstaller
                        .getServiceUnitProperties(componentInstance);
                try {
                    final FileOutputStream fos = new FileOutputStream(propertiesFile);
                    try {
                        serviceUnitProperties.store(fos, "");
                    } catch (final IOException e) {
                        throw new PluginException(String.format(
                                "An error occurs writing the properties file '%s' of component '%s'.",
                                propertiesFileName, componentInstance.getName()), e);
                    } finally {
                        try {
                            fos.close();
                        } catch (IOException e) {
                            this.logger.log(Level.WARNING, "An error occurs closing the properties file", e);
                        }
                    }
                } catch (final FileNotFoundException e) {
                    throw new PluginException(String.format(
                            "The properties file '%s' of component '%s' can not be created.", propertiesFileName,
                            componentInstance.getName()), e);
                }
            } else {
                throw new PluginException(String.format(
                        "Invalid value ('%s') for the properties file of component '%s'.", propertiesFileName,
                        componentInstance.getName()));
            }
        } else {
            this.logger.fine(String.format(
                    "No properties file defined for component '%s'. Its exported variables are: %s",
                    componentInstance.getName(), componentInstance.overriddenExports.toString()));
        }

        // We configure the component
        final Properties placeHolders = new Properties();
        placeHolders.setProperty("container-name", this.retrieveContainerInstance(componentInstance).getName());
        placeHolders.setProperty("component-name", componentInstance.getName());
        final Properties configurationProperties = super.getConfigurationProperties(componentInstance);
        for (final Entry<String, String> entry : componentInstance.overriddenExports.entrySet()) {
            final String propertyName = entry.getKey().substring(entry.getKey().lastIndexOf('.') + 1);
            try {
                configurationProperties.setProperty(propertyName,
                        PropertiesHelper.resolveString(entry.getValue(), placeHolders));
            } catch (final PropertiesException e) {
                this.logger.log(Level.WARNING,
                        String.format("An error occurs resolving the property '%s'", entry.getKey()), e);
            }
        }

        return configurationProperties;
    }

    /**
     * <p>
     * Retrieve the property file name of the JBI component given as {@link Instance}.
     * </p>
     * <p>
     * If the container name or the component name are used as placeholder (<code>${container-name}</code>,
     * <code>${component-name}</code> in the properties file name, they will be resolved.</code>
     * 
     * @param componentInstance
     *            Roboconf component instance associated to the Petals JBI component to deploy
     * @return The properties file name of the JBI component, or <code>null</code> if not defined.
     * @throws PluginException
     */
    private String getPropertiesFileName(final Instance componentInstance) throws PluginException {

        try {
            final String propertiesFileName = componentInstance.overriddenExports
                    .get(COMPONENT_VARIABLE_NAME_PROPERTIESFILE);
            if (propertiesFileName != null && !propertiesFileName.isEmpty()) {
                final Properties placeHolders = new Properties();
                placeHolders.setProperty("container-name", this.retrieveContainerInstance(componentInstance).getName());
                placeHolders.setProperty("component-name", componentInstance.getName());
                return PropertiesHelper.resolveString(propertiesFileName, placeHolders);
            } else {
                return null;
            }
        } catch (final PropertiesException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void update(final Instance instance, final Import importChanged, final InstanceStatus statusChanged)
            throws PluginException {
        // TODO: Reload properties conf file for JBI component
    }

    /**
     * Retrieve all configuration properties of service units to set at component level (in its properties file)
     * 
     * @param componentInstance
     * @return
     * @throws PluginException
     */
    private final static Properties getServiceUnitProperties(final Instance componentInstance) throws PluginException {

        final Properties serviceUnitsProperties = new Properties();
        for (final Instance serviceUnitInstance : componentInstance.getChildren()) {

            if (!ROBOCONF_COMPONENT_SU_COMPONENT.equals(serviceUnitInstance.getComponent().getExtendedComponent()
                    .getName())) {
                throw new PluginException(String.format(
                        "Unexpected parent for '%s' (child of '%s). It MUST be inherited from '%s' (current '%s')",
                        serviceUnitInstance.getName(), componentInstance.getName(), ROBOCONF_COMPONENT_SU_COMPONENT,
                        serviceUnitInstance.getComponent().getExtendedComponent().getName()));
            } else {
                for (final Entry<String, String> entry : serviceUnitInstance.overriddenExports.entrySet()) {
                    serviceUnitsProperties.setProperty(entry.getKey(), entry.getValue());
                }

                // TODO: Add imports as configuration parameter properties for SU depending on other Roboconf components
                // or applications

            }
        }
        return serviceUnitsProperties;
    }
}
