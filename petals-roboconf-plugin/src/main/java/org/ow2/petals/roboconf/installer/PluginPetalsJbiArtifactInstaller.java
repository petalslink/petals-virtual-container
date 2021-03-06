/**
 * Copyright (c) 2015-2018 Linagora
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
 * along with this program/library; If not, see http://www.gnu.org/licenses/
 * for the GNU Lesser General Public License version 2.1.
 */
package org.ow2.petals.roboconf.installer;

import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_CONTAINER;

import java.io.File;
import java.net.MalformedURLException;
import java.util.Map;
import java.util.Properties;

import org.ow2.petals.admin.api.artifact.ConfigurationPropertiesCallback;
import org.ow2.petals.admin.api.artifact.exception.ConfigurationParamComputeException;
import org.ow2.petals.admin.api.exception.ArtifactAdministrationException;
import org.ow2.petals.admin.api.exception.ContainerAdministrationException;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;

import net.roboconf.core.model.beans.Component;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.plugin.api.PluginException;
import net.roboconf.plugin.api.PluginInterface;

public abstract class PluginPetalsJbiArtifactInstaller extends PluginPetalsAbstractInstaller implements PluginInterface {

    public PluginPetalsJbiArtifactInstaller() throws DuplicatedServiceException, MissingServiceException {
        super();
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {
        // Deploy the SL
        this.logger.fine(this.agentId + ": deploying the " + this.getManagedArtifactType() + " for instance "
                + instance);
        final File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(instance);
        final File jbiArtifactFile = new File(instanceDirectory, instance.getName() + ".zip");
        // TODO: Try to improve access to the java SPI of Petals Admin using a dedicated bundle for Petals Admin API
        // instead of setting the classloader
        final ClassLoader old = Thread.currentThread().getContextClassLoader();
        Thread.currentThread().setContextClassLoader(PluginPetalsJbiArtifactInstaller.class.getClassLoader());
        try {
            this.connectToContainer(this.retrieveContainerInstance(instance));
            try {
                this.adminApi.newArtifactAdministration().deployAndStartArtifact(jbiArtifactFile.toURI().toURL(),
                        new ConfigurationPropertiesCallback() {

                            @Override
                            public Properties compute(final Map<String, String> oldConfigParam)
                                    throws ConfigurationParamComputeException {
                                try {
                                return PluginPetalsJbiArtifactInstaller.this.getConfigurationProperties(instance,
                                        oldConfigParam);
                                } catch (final PluginException e) {
                                    throw new ConfigurationParamComputeException(e);
                                }
                            }
                        }, true);

            } catch (final MalformedURLException e) {
                // This error should not occur
                throw new PluginException(e);
            } finally {
                this.adminApi.disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        } finally {
            Thread.currentThread().setContextClassLoader(old);
        }
    }

    protected Properties getConfigurationProperties(final Instance jbiArtifactInstance,
            final Map<String, String> existingConfParams) throws PluginException {
        return new Properties();
    }

    @Override
    protected String getManagedArtifactName(final Instance jbiArtifactInstance) {
        return jbiArtifactInstance.getName();
    }

    @Override
    protected String getManagedArtifactVersion() {
        return null;
    }

    @Override
    protected final Instance retrieveContainerInstance(final Instance jbiArtifactInstance) throws PluginException {

        // TODO: Perhaps review how to retrieve container exported variables when
        // https://github.com/roboconf/roboconf-platform/issues/184 will be fixed

        final Instance containerInstance = jbiArtifactInstance.getParent();
        final Component jbiComponentAbstractContainer = containerInstance.getComponent().getExtendedComponent();
        if (jbiComponentAbstractContainer == null) {
            throw new PluginException(String.format("No parent defined for the %s. It MUST be inherited from '%s'",
                    this.getManagedArtifactType(), ROBOCONF_COMPONENT_ABTRACT_CONTAINER));
        } else if (!ROBOCONF_COMPONENT_ABTRACT_CONTAINER.equals(jbiComponentAbstractContainer.getName())) {
            throw new PluginException(
                    String.format("Unexpected parent for the %s. It MUST be inherited from '%s' (current '%s')",
                            this.getManagedArtifactType(), ROBOCONF_COMPONENT_ABTRACT_CONTAINER,
                            jbiComponentAbstractContainer.getName()));
        }
        return containerInstance;
    }

}
