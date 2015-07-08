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
import java.net.MalformedURLException;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import net.roboconf.core.model.beans.Import;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.beans.Instance.InstanceStatus;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.plugin.api.PluginException;
import net.roboconf.plugin.api.PluginInterface;

import org.apache.commons.io.IOUtils;
import org.ow2.petals.admin.api.PetalsAdministrationFactory;
import org.ow2.petals.admin.api.exception.ArtifactAdministrationException;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;
import org.ow2.petals.jbi.descriptor.JBIDescriptorException;
import org.ow2.petals.jbi.descriptor.original.JBIDescriptorBuilder;
import org.ow2.petals.jbi.descriptor.original.generated.Identification;
import org.ow2.petals.jbi.descriptor.original.generated.Jbi;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceAssembly;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceUnit;
import org.ow2.petals.jbi.descriptor.original.generated.Target;

public class PluginPetals implements PluginInterface {

    private static final String PLUGIN_NAME = "petals";

    private static final String SA_NAME_TEMPLATE = "sa-%s";

    private final Logger logger = Logger.getLogger(getClass().getName());

    private String agentId;

    @Override
    public void initialize(final Instance instance) throws PluginException {
        // NOP
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {

        File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(instance);
        final File suFile = new File(instanceDirectory, instance.getName() + ".zip");

        // Generate the SA including the SU
        this.logger.fine(this.agentId + " is generating the SA associated to the instance " + instance);
        final Jbi saJbiDescriptor = new Jbi();
        final ServiceAssembly serviceAssembly = new ServiceAssembly();
        final Identification saIdentifiaction = new Identification();
        saIdentifiaction.setName(PluginPetals.getSAName(instance));
        serviceAssembly.setIdentification(saIdentifiaction);
        final ServiceUnit serviceUnit = new ServiceUnit();
        final Identification suIdentifiaction = new Identification();
        suIdentifiaction.setName(instance.getName());
        serviceUnit.setIdentification(suIdentifiaction);
        final Target componentTarget = new Target();
        componentTarget.setArtifactsZip(suFile.getName());
        componentTarget.setComponentName(instance.getParent().getName());
        serviceUnit.setTarget(componentTarget);
        serviceAssembly.getServiceUnit().add(serviceUnit);
        saJbiDescriptor.setServiceAssembly(serviceAssembly);

        try {
            final File saFile = File.createTempFile(PluginPetals.getSAName(instance), ".zip");
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
                zipOutputStream.putNextEntry(suEntry);
                JBIDescriptorBuilder.getInstance().writeXMLJBIdescriptor(saJbiDescriptor, zipOutputStream);
                zipOutputStream.closeEntry();
            }

            // Deploy the SA previously generated
            this.logger.fine(this.agentId + " is deploying the SA associated to the instance " + instance);
            try {
                PetalsAdministrationFactory.newInstance().newArtifactAdministration()
                        .deployAndStartArtifact(saFile.toURI().toURL(), true);
            } catch (final MalformedURLException e) {
                // This error should not occur because the URL is generated from a local file
                this.logger.log(Level.WARNING, "An error occurs", e);
            }
        } catch (final IOException | JBIDescriptorException | ArtifactAdministrationException
                | DuplicatedServiceException | MissingServiceException e) {
            throw new PluginException(e);
        }

    }

    @Override
    public void start(final Instance instance) throws PluginException {
        // Start the SA previously generated
        this.logger.fine(this.agentId + " is starting the SA associated to the instance " + instance);
        try {
            PetalsAdministrationFactory.newInstance().newArtifactAdministration()
                    .startArtifact("SA", PluginPetals.getSAName(instance));
        } catch (final ArtifactAdministrationException | DuplicatedServiceException | MissingServiceException e) {
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
            PetalsAdministrationFactory.newInstance().newArtifactAdministration()
                    .stopArtifact("SA", PluginPetals.getSAName(instance));
        } catch (final ArtifactAdministrationException | DuplicatedServiceException | MissingServiceException e) {
            throw new PluginException(e);
        }
    }

    @Override
    public void undeploy(final Instance instance) throws PluginException {
        // Undeploy the SA previously generated
        this.logger.fine(this.agentId + " is undeploying the SA associated to the instance " + instance);
        try {
            PetalsAdministrationFactory.newInstance().newArtifactAdministration()
                    .stopAndUndeployArtifact("SA", PluginPetals.getSAName(instance), null);
        } catch (final ArtifactAdministrationException | DuplicatedServiceException | MissingServiceException e) {
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

    private final static String getSAName(final Instance instance) {
        return String.format(SA_NAME_TEMPLATE, instance.getName());
    }

}
