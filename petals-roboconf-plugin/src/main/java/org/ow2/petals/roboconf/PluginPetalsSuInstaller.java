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
package org.ow2.petals.roboconf;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import net.roboconf.core.model.beans.Component;
import net.roboconf.core.model.beans.Import;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.beans.Instance.InstanceStatus;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.plugin.api.PluginException;
import net.roboconf.plugin.api.PluginInterface;

import org.apache.commons.io.IOUtils;
import org.ow2.petals.admin.api.ContainerAdministration;
import org.ow2.petals.admin.api.PetalsAdministrationFactory;
import org.ow2.petals.admin.api.exception.ArtifactAdministrationException;
import org.ow2.petals.admin.api.exception.ContainerAdministrationException;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;
import org.ow2.petals.jbi.descriptor.JBIDescriptorException;
import org.ow2.petals.jbi.descriptor.original.JBIDescriptorBuilder;
import org.ow2.petals.jbi.descriptor.original.generated.Identification;
import org.ow2.petals.jbi.descriptor.original.generated.Jbi;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceAssembly;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceUnit;
import org.ow2.petals.jbi.descriptor.original.generated.Target;

public class PluginPetalsSuInstaller implements PluginInterface {

    private static final String PLUGIN_NAME = "petals-su-installer";

    private static final String SA_NAME_TEMPLATE = "sa-%s";

    /**
     * Name of the Roboconf component associated to an abstract Petals JBI component
     */
    protected static final String ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT = "PetalsJBIComponent";

    /**
     * Name of the Roboconf component associated to an abstract Petals container
     */
    protected static final String ROBOCONF_COMPONENT_ABTRACT_CONTAINER = "PetalsContainerTemplate";

    protected static final String CONTAINER_VARIABLE_NAME_IP = ROBOCONF_COMPONENT_ABTRACT_CONTAINER + ".ip";

    protected static final String CONTAINER_VARIABLE_NAME_JMXPORT = ROBOCONF_COMPONENT_ABTRACT_CONTAINER + ".jmxPort";

    protected static final String CONTAINER_VARIABLE_NAME_JMXUSER = ROBOCONF_COMPONENT_ABTRACT_CONTAINER + ".jmxUser";

    protected static final String CONTAINER_VARIABLE_NAME_JMXPASSWORD = ROBOCONF_COMPONENT_ABTRACT_CONTAINER
            + ".jmxPassword";

    private final Logger logger = Logger.getLogger(getClass().getName());

    private String agentId;

    private PetalsAdministrationFactory paf;

    public PluginPetalsSuInstaller() throws DuplicatedServiceException, MissingServiceException {
        this.paf = PetalsAdministrationFactory.newInstance();
    }

    @Override
    public void initialize(final Instance instance) throws PluginException {
        // NOP
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {

        File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(instance);
        final File suFile = new File(instanceDirectory, instance.getName() + ".zip");
        try {
            final File saFile = File.createTempFile(PluginPetalsSuInstaller.getSAName(instance), ".zip");

            // Generate the SA including the SU
            this.logger.fine(this.agentId + " is generating the SA (" + saFile.getAbsolutePath()
                    + ") associated to the instance " + instance);
            final Jbi saJbiDescriptor = new Jbi();
            saJbiDescriptor.setVersion(new BigDecimal(1));
            final ServiceAssembly serviceAssembly = new ServiceAssembly();
            final Identification saIdentifiaction = new Identification();
            saIdentifiaction.setName(PluginPetalsSuInstaller.getSAName(instance));
            saIdentifiaction.setDescription("");
            serviceAssembly.setIdentification(saIdentifiaction);
            final ServiceUnit serviceUnit = new ServiceUnit();
            final Identification suIdentifiaction = new Identification();
            suIdentifiaction.setName(instance.getName());
            suIdentifiaction.setDescription("");
            serviceUnit.setIdentification(suIdentifiaction);
            final Target componentTarget = new Target();
            componentTarget.setArtifactsZip(suFile.getName());
            componentTarget.setComponentName(instance.getParent().getName());
            serviceUnit.setTarget(componentTarget);
            serviceAssembly.getServiceUnit().add(serviceUnit);
            saJbiDescriptor.setServiceAssembly(serviceAssembly);

            try (final OutputStream saOutputStream = new FileOutputStream(saFile);
                    final ZipOutputStream zipOutputStream = new ZipOutputStream(saOutputStream)) {

                // ZIP entry associated to the SU archive
                final ZipEntry suEntry = new ZipEntry(suFile.getName());
                zipOutputStream.putNextEntry(suEntry);
                try (final InputStream suInputStream = new FileInputStream(suFile)) {
                    IOUtils.copy(suInputStream, zipOutputStream);
                }
                zipOutputStream.closeEntry();

                // ZIP entry associated to the JBI descriptor
                final ZipEntry jbiDescrEntry = new ZipEntry(JBIDescriptorBuilder.JBI_DESCRIPTOR_RESOURCE_IN_ARCHIVE);
                zipOutputStream.putNextEntry(jbiDescrEntry);
                JBIDescriptorBuilder.getInstance().writeXMLJBIdescriptor(saJbiDescriptor, zipOutputStream);
                zipOutputStream.closeEntry();
            }

            // Deploy the SA previously generated
            this.logger.fine(this.agentId + " is deploying the SA associated to the instance " + instance);
            this.connectToContainer(instance);
            try {
                this.paf.newArtifactAdministration().deployAndStartArtifact(saFile.toURI().toURL(), true);
            } catch (final MalformedURLException e) {
                // This error should not occur because the URL is generated from a local file
                this.logger.log(Level.WARNING, "An error occurs", e);
            } catch (final NumberFormatException e) {
                throw new PluginException("Invalid value for JMX port (Not a number)", e);
            } finally {
                this.paf.newContainerAdministration().disconnect();
            }
        } catch (final IOException | JBIDescriptorException | ContainerAdministrationException
                | ArtifactAdministrationException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void start(final Instance instance) throws PluginException {
        // Start the SA previously generated
        this.logger.fine(this.agentId + " is starting the SA associated to the instance " + instance);
        try {
            this.connectToContainer(instance);
            try {
                this.paf.newArtifactAdministration().startArtifact("SA", PluginPetalsSuInstaller.getSAName(instance));
            } finally {
                this.paf.newContainerAdministration().disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void update(final Instance instance, final Import importChanged, final InstanceStatus statusChanged)
            throws PluginException {
        // TODO Auto-generated method stub

    }

    @Override
    public void stop(final Instance instance) throws PluginException {
        // Stop the SA previously generated
        this.logger.fine(this.agentId + " is stopping the SA associated to the instance " + instance);
        try {
            this.connectToContainer(instance);
            try {
                this.paf.newArtifactAdministration().stopArtifact("SA", PluginPetalsSuInstaller.getSAName(instance));
            } finally {
                this.paf.newContainerAdministration().disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void undeploy(final Instance instance) throws PluginException {
        // Undeploy the SA previously generated
        this.logger.fine(this.agentId + " is undeploying the SA associated to the instance " + instance);
        try {
            this.connectToContainer(instance);
            try {
                this.paf.newArtifactAdministration().stopAndUndeployArtifact("SA",
                        PluginPetalsSuInstaller.getSAName(instance), null);
            } finally {
                this.paf.newContainerAdministration().disconnect();
            }
        } catch (final ArtifactAdministrationException | ContainerAdministrationException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void setNames(final String applicationName, final String rootInstanceName) {
        this.agentId = "'" + rootInstanceName + "' agent";
    }

    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }

    /**
     * A method dedicated to unit tests to inject the Petals Administration Mock as Petals Admin API implementation.
     */
    protected void setPetalsAdministrationApi(final PetalsAdministrationFactory paf) {
        this.paf = paf;
    }

    private final void connectToContainer(final Instance instance) throws ContainerAdministrationException,
            PluginException {

        final Instance jbiComponentInstance = instance.getParent();
        final Component jbiComponentAbstractJbiComponent = jbiComponentInstance.getComponent().getExtendedComponent();
        if (jbiComponentAbstractJbiComponent == null
                || !ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT.equals(jbiComponentAbstractJbiComponent.getName())) {
            throw new PluginException(String.format(
                    "Unexpected parent for the Service Unit. It MUST be inherited from '%s'",
                    ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT));
        }
        final Instance containerInstance = jbiComponentInstance.getParent();
        final Component containerComponent = containerInstance.getComponent();
        final Component jbiComponentAbstractContainer = containerComponent.getExtendedComponent();
        if (jbiComponentAbstractContainer == null
                || !ROBOCONF_COMPONENT_ABTRACT_CONTAINER.equals(jbiComponentAbstractContainer.getName())) {
            throw new PluginException(String.format(
                    "Unexpected parent for the JBI component running the Service Unit. It MUST be inherited from '%s'",
                    ROBOCONF_COMPONENT_ABTRACT_CONTAINER));
        }
        final Map<String, String> containerExportedVariables = containerComponent.exportedVariables;
        final String ip = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_IP);
        final String jmxPort = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXPORT);
        final String jmxUser = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXUSER);
        final String jmxPassword = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXPASSWORD);
        if (ip == null || ip.isEmpty() || jmxPort == null || jmxPort.isEmpty() || jmxUser == null
                || jmxPassword == null) {
            throw new PluginException("An exported variables is missing. Available exported variables are: "
                    + containerExportedVariables);
        } else {
            this.logger.fine("Exported variables of container: " + containerExportedVariables);
        }

        try {
            final ContainerAdministration pafContainer = this.paf.newContainerAdministration();
            pafContainer.connect(ip, Integer.parseInt(jmxPort), jmxUser, jmxPassword);
        } catch (final NumberFormatException e) {
            throw new PluginException("Invalid value for JMX port (Not a number)", e);
        }
    }

    protected final static String getSAName(final Instance instance) {
        return String.format(SA_NAME_TEMPLATE, instance.getName());
    }

}
