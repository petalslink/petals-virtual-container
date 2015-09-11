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

import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_IP;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPASSWORD;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPORT;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXUSER;

import java.util.Map;
import java.util.logging.Logger;

import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.plugin.api.PluginException;
import net.roboconf.plugin.api.PluginInterface;

import org.ow2.petals.admin.api.ArtifactAdministration;
import org.ow2.petals.admin.api.ContainerAdministration;
import org.ow2.petals.admin.api.PetalsAdministrationFactory;
import org.ow2.petals.admin.api.exception.ArtifactAdministrationException;
import org.ow2.petals.admin.api.exception.ContainerAdministrationException;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;

public abstract class PluginPetalsAbstractInstaller implements PluginInterface {

    protected final Logger logger = Logger.getLogger(getClass().getName());

    protected String agentId;

    protected ArtifactAdministration artifactAdministration;

    protected ContainerAdministration containerAdministration;

    public PluginPetalsAbstractInstaller() throws DuplicatedServiceException, MissingServiceException {
        // TODO: Try to improve access to the java SPI of Petals Admin using a dedicated bundle for Petals Admin API instead of setting the classloader
        final ClassLoader old = Thread.currentThread().getContextClassLoader();
        Thread.currentThread().setContextClassLoader(PluginPetalsAbstractInstaller.class.getClassLoader());
        try {
            final PetalsAdministrationFactory paf = PetalsAdministrationFactory.newInstance();
            this.setPetalsAdministrationApi(paf);
        } finally {
            Thread.currentThread().setContextClassLoader(old);
        }
    }

    @Override
    public void initialize(final Instance instance) throws PluginException {
        this.logger.fine(this.agentId + ": initializing the plugin for instance " + instance);
    }

    @Override
    public void start(final Instance instance) throws PluginException {
        // Start the SA previously generated
        this.logger
                .fine(this.agentId + ": starting the " + this.getManagedArtifactType() + " for instance " + instance);
        try {
            this.connectToContainer(this.retrieveContainerInstance(instance));
            try {
                this.artifactAdministration.startArtifact(this.getManagedArtifactType(),
                        this.getManagedArtifactName(instance));
            } finally {
                this.containerAdministration.disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        }
    }

    /**
     * @return The type of the managed artifact according to the values expected by
     *         {@link ArtifactAdministration#startArtifact(String, String)}.
     */
    protected abstract String getManagedArtifactType();

    /**
     * @return The name of the managed artifact to be used by methods of {@link ArtifactAdministration}.
     */
    protected abstract String getManagedArtifactName(final Instance artifactInstance);

    @Override
    public void stop(final Instance instance) throws PluginException {
        // Stop the SA previously generated
        this.logger
                .fine(this.agentId + ": stopping the " + this.getManagedArtifactType() + " for instance " + instance);
        try {
            this.connectToContainer(this.retrieveContainerInstance(instance));
            try {
                this.artifactAdministration.stopArtifact(this.getManagedArtifactType(),
                        this.getManagedArtifactName(instance));
            } finally {
                this.containerAdministration.disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void undeploy(final Instance instance) throws PluginException {
        // Undeploy the SA previously generated
        this.logger.fine(this.agentId + ": undeploying the " + this.getManagedArtifactType() + " for instance "
                + instance);
        try {
            this.connectToContainer(this.retrieveContainerInstance(instance));
            try {
                this.artifactAdministration.stopAndUndeployArtifact(this.getManagedArtifactType(),
                        this.getManagedArtifactName(instance), this.getManagedArtifactVersion());
            } finally {
                this.containerAdministration.disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        }
    }

    /**
     * @return The version of the managed artifact according to the values expected by
     *         {@link ArtifactAdministration#stopAndUndeployArtifact(String, String, String)}.
     */
    protected abstract String getManagedArtifactVersion();

    @Override
    public void setNames(final String applicationName, final String rootInstanceName) {
        this.agentId = "'" + rootInstanceName + "' agent";
    }

    /**
     * A method dedicated to unit tests to inject the Petals Administration Mock as Petals Admin API implementation.
     */
    protected void setPetalsAdministrationApi(final PetalsAdministrationFactory paf) {
        this.artifactAdministration = paf.newArtifactAdministration();
        this.containerAdministration = paf.newContainerAdministration();
    }

    /**
     * Retrieve the container instance from the current artifact instance
     * 
     * @param artifactInstance
     * @return
     * @throws ContainerAdministrationException
     * @throws PluginException
     */
    protected abstract Instance retrieveContainerInstance(final Instance artifactInstance)
            throws ContainerAdministrationException, PluginException;

    protected final void connectToContainer(final Instance containerInstance) throws ContainerAdministrationException,
            PluginException {

        final Map<String, String> containerExportedVariables = InstanceHelpers
                .findAllExportedVariables(containerInstance);
        final String ip = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_IP);
        final String jmxPort = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXPORT);
        final String jmxUser = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXUSER);
        final String jmxPassword = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXPASSWORD);
        if (ip == null || ip.isEmpty() || jmxPort == null || jmxPort.isEmpty() || jmxUser == null
                || jmxPassword == null) {
            throw new PluginException("An exported variable is missing. Available exported variables are: "
                    + containerExportedVariables);
        } else {
            this.logger.fine("Exported variables of container: " + containerExportedVariables);
        }

        try {
            this.containerAdministration.connect(ip, Integer.parseInt(jmxPort), jmxUser, jmxPassword);
        } catch (final NumberFormatException e) {
            throw new PluginException("Invalid value for JMX port (Not a number)", e);
        }
    }

}
