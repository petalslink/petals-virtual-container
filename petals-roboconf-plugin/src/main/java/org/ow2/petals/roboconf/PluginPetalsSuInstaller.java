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
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.util.logging.Level;
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
import org.ow2.petals.admin.api.exception.ContainerAdministrationException;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;
import org.ow2.petals.jbi.descriptor.original.JBIDescriptorBuilder;
import org.ow2.petals.jbi.descriptor.original.generated.Identification;
import org.ow2.petals.jbi.descriptor.original.generated.Jbi;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceAssembly;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceUnit;
import org.ow2.petals.jbi.descriptor.original.generated.Target;

public class PluginPetalsSuInstaller extends PluginPetalsAbstractInstaller implements PluginInterface {

    private static final String PLUGIN_NAME = "petals-su-installer";

    private static final String SA_NAME_TEMPLATE = "sa-%s";

    public PluginPetalsSuInstaller() throws DuplicatedServiceException, MissingServiceException {
        super();
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {

        File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(instance);
        final File suFile = new File(instanceDirectory, instance.getName() + ".zip");
        // TODO: Try to improve access to the java SPI of Petals Admin using a dedicated bundle for Petals Admin API instead of setting the classloader
        final ClassLoader old = Thread.currentThread().getContextClassLoader();
        Thread.currentThread().setContextClassLoader(PluginPetalsSuInstaller.class.getClassLoader());
        try {
            final File saFile = File.createTempFile(PluginPetalsSuInstaller.getSAName(instance), ".zip");

            // Generate the SA including the SU
            this.logger.fine(this.agentId + ": generating the SA (" + saFile.getAbsolutePath() + ") for instance "
                    + instance + " from the SU " + suFile.getAbsolutePath());
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
                this.logger.fine(this.agentId + ": putting the SU into the SA");
                final ZipEntry suEntry = new ZipEntry(suFile.getName());
                zipOutputStream.putNextEntry(suEntry);
                try (final InputStream suInputStream = new FileInputStream(suFile)) {
                    IOUtils.copy(suInputStream, zipOutputStream);
                }
                zipOutputStream.closeEntry();

                // ZIP entry associated to the JBI descriptor
                this.logger.fine(this.agentId + ": putting the JBI descriptor into the SA");
                final ZipEntry jbiDescrEntry = new ZipEntry(JBIDescriptorBuilder.JBI_DESCRIPTOR_RESOURCE_IN_ARCHIVE);
                zipOutputStream.putNextEntry(jbiDescrEntry);
                JBIDescriptorBuilder.getInstance().writeXMLJBIdescriptor(saJbiDescriptor, zipOutputStream);
                zipOutputStream.closeEntry();
            }

            // Deploy the SA previously generated
            this.logger.fine(this.agentId + ": deploying the SA for instance " + instance);
            this.connectToContainer(this.retrieveContainerInstance(instance));
            try {
                this.artifactAdministration.deployAndStartArtifact(saFile.toURI().toURL(), true);
            } catch (final MalformedURLException e) {
                // This error should not occur because the URL is generated from a local file
                this.logger.log(Level.WARNING, "An error occurs", e);
            } catch (final NumberFormatException e) {
                throw new PluginException("Invalid value for JMX port (Not a number)", e);
            } finally {
                this.containerAdministration.disconnect();
            }
        } catch (final Throwable e) {
            this.logger.log(Level.SEVERE, "An error occurs", e);
            throw new PluginException(e);
        } finally {
            Thread.currentThread().setContextClassLoader(old);
        }
    }

    @Override
    public void update(final Instance instance, final Import importChanged, final InstanceStatus statusChanged)
            throws PluginException {
        // NOP
    }

    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }

    @Override
    protected String getManagedArtifactType() {
        return "SA";
    }

    @Override
    protected String getManagedArtifactName(final Instance suInstance) {
        return PluginPetalsSuInstaller.getSAName(suInstance);
    }

    @Override
    protected String getManagedArtifactVersion() {
        return null;
    }

    @Override
    protected final Instance retrieveContainerInstance(final Instance suInstance)
            throws ContainerAdministrationException,
            PluginException {

        // TODO: Perhaps review how to retrieve container exported variables when
        // https://github.com/roboconf/roboconf-platform/issues/184 will be fixed

        final Instance seOrBcInstance = suInstance.getParent();
        final Component seOrBcComponent = seOrBcInstance.getComponent().getExtendedComponent();
        if (seOrBcComponent == null
                || (!ROBOCONF_COMPONENT_SE_COMPONENT.equals(seOrBcComponent.getName()) && !ROBOCONF_COMPONENT_BC_COMPONENT
                        .equals(seOrBcComponent.getName()))) {
            throw new PluginException(String.format(
                    "Unexpected parent for the Service Unit. It MUST be inherited from '%s' or '%s' (current '%s')",
                    ROBOCONF_COMPONENT_SE_COMPONENT, ROBOCONF_COMPONENT_BC_COMPONENT, seOrBcComponent.getName()));
        }
        final Component jbiComponentComponent = seOrBcComponent.getExtendedComponent();
        if (jbiComponentComponent == null
                || !ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT.equals(jbiComponentComponent.getName())) {
            throw new PluginException(String.format(
                    "Unexpected parent for the Service Unit. It MUST be inherited from '%s' (current '%s')",
                    ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT, jbiComponentComponent.getName()));
        }
        final Instance containerInstance = seOrBcInstance.getParent();
        final Component jbiComponentAbstractContainer = containerInstance.getComponent().getExtendedComponent();
        if (jbiComponentAbstractContainer == null
                || !ROBOCONF_COMPONENT_ABTRACT_CONTAINER.equals(jbiComponentAbstractContainer.getName())) {
            throw new PluginException(
                    String.format(
                            "Unexpected parent for the JBI component running the Service Unit. It MUST be inherited from '%s' (current '%s')",
                            ROBOCONF_COMPONENT_ABTRACT_CONTAINER, jbiComponentAbstractContainer.getName()));
        }
        return containerInstance;
    }

    protected final static String getSAName(final Instance instance) {
        return String.format(SA_NAME_TEMPLATE, instance.getName());
    }

}
