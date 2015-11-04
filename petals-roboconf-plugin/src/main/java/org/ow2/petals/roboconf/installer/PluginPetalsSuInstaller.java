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
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_CONTAINER;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_BC_COMPONENT;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_SE_COMPONENT;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.util.Collection;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Properties;
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
import org.ow2.petals.admin.api.exception.ArtifactAdministrationException;
import org.ow2.petals.admin.api.exception.ContainerAdministrationException;
import org.ow2.petals.admin.api.exception.DuplicatedServiceException;
import org.ow2.petals.admin.api.exception.MissingServiceException;
import org.ow2.petals.jbi.descriptor.original.JBIDescriptorBuilder;
import org.ow2.petals.jbi.descriptor.original.generated.Identification;
import org.ow2.petals.jbi.descriptor.original.generated.Jbi;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceAssembly;
import org.ow2.petals.jbi.descriptor.original.generated.ServiceUnit;
import org.ow2.petals.jbi.descriptor.original.generated.Target;
import org.ow2.petals.roboconf.Utils;

import com.ebmwebsourcing.easycommons.properties.PropertiesException;
import com.ebmwebsourcing.easycommons.properties.PropertiesHelper;

public class PluginPetalsSuInstaller extends PluginPetalsAbstractInstaller implements PluginInterface {

    private static final String PLUGIN_NAME = "petals-su-installer";

    private static final String SA_NAME_TEMPLATE = "sa-%s";

    public PluginPetalsSuInstaller() throws DuplicatedServiceException, MissingServiceException {
        super();
    }

    @Override
    public void deploy(final Instance instance) throws PluginException {
        // NOP: Hack to workaround https://github.com/roboconf/roboconf-platform/issues/331
        // TODO: Rename localDeploy(...) into deploy(...) when https://github.com/roboconf/roboconf-platform/issues/331
        // will be fixed
    }

    private void localDeploy(final Instance instance) throws PluginException {

        File instanceDirectory = InstanceHelpers.findInstanceDirectoryOnAgent(instance);
        final File suFile = new File(instanceDirectory, instance.getName() + ".zip");
        // TODO: Try to improve access to the java SPI of Petals Admin using a dedicated bundle for Petals Admin API
        // instead of setting the classloader
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
    public void start(final Instance suInstance) throws PluginException {
        // NOP: Hack to workaround https://github.com/roboconf/roboconf-platform/issues/331
        // TODO: Remove when https://github.com/roboconf/roboconf-platform/issues/331 will be fixed
        this.localDeploy(suInstance);

        this.updatePropertiesFile(suInstance);
        super.start(suInstance);
    }

    @Override
    public void update(final Instance suInstance, final Import importChanged, final InstanceStatus statusChanged)
            throws PluginException {

        this.logger.fine(this.agentId + ": updating the " + this.getManagedArtifactType() + " for instance "
                + suInstance);
        this.updatePropertiesFile(suInstance);
    }

    private void updatePropertiesFile(final Instance suInstance) throws PluginException {

        final Instance componentInstance = suInstance.getParent();

        this.logger.fine(this.agentId + ": updating the properties file for JBI component instance "
                + componentInstance);

        final String propertiesFileName = Utils
                .resolvePropertiesFileName(
                        InstanceHelpers.findAllExportedVariables(componentInstance)
                .get(COMPONENT_VARIABLE_NAME_PROPERTIESFILE), this.retrieveContainerInstance(suInstance).getName(),
                componentInstance.getName());
        this.logger.fine("Updated file: " + propertiesFileName);
        if (propertiesFileName != null && !propertiesFileName.isEmpty()) {
            final File propertiesFile = new File(propertiesFileName);
            if (!propertiesFile.exists()
                    || (propertiesFile.exists() && propertiesFile.canWrite() && propertiesFile.isFile())) {

                // If the properties file exists, we read it
                final Properties properties = new Properties();
                if (propertiesFile.exists()) {
                    try {
                        final InputStream fis = new FileInputStream(propertiesFile);
                        try {
                            properties.load(fis);
                        } catch (final IOException e) {
                            throw new PluginException(String.format(
                                    "Error reading the properties file ('%s') of component '%s'.", propertiesFileName,
                                    componentInstance.getName()));
                        } finally {
                            try {
                                fis.close();
                            } catch (final IOException e) {
                                this.logger.log(Level.WARNING, String.format(
                                        "An error occurs closing the properties file '%s'", propertiesFileName), e);
                            }
                        }
                    } catch (final FileNotFoundException e) {
                        // This exception should not occur because we have previously verified that the file exists
                        this.logger.log(Level.WARNING, String.format(
                                "The properties file ('%s') of component '%s' no more exist", propertiesFileName,
                                componentInstance.getName()), e);
                    }
                }

                // Update property values with values coming from SU imports
                final Map<String, Collection<Import>> allImportedVariables = suInstance.getImports();
                final Properties importedValues = new Properties();
                for (final Entry<String, Collection<Import>> importEntry : allImportedVariables.entrySet()) {
                    for (final Import anImport : importEntry.getValue()) {
                        for (final Entry<String, String> anExportImported : anImport.getExportedVars().entrySet()) {
                            importedValues.setProperty(anExportImported.getKey(), anExportImported.getValue());
                        }
                    }
                }
                this.logger.fine(String.format("Imported variables used by the SU: %s", importedValues.toString()));

                final Map<String, String> allExportedVariables = InstanceHelpers.findAllExportedVariables(suInstance);
                this.logger
                        .fine(String.format("All exported variables of the SU: %s", allExportedVariables.toString()));
                for (final Entry<String, String> entry : allExportedVariables.entrySet()) {
                    // We must remove the SU component name implicitely added in exported variables
                    final String keyName;
                    if (entry.getKey().startsWith(suInstance.getComponent().getName())) {
                        keyName = entry.getKey().substring(suInstance.getComponent().getName().length() + 1);
                    } else {
                        keyName = entry.getKey();
                    }

                    // We resolved placeholder of the exported variable value with imported variables
                    try {
                        final String keyValue = PropertiesHelper.resolveString(entry.getValue(), importedValues);
                        properties.setProperty(keyName, keyValue);
                    } catch (final PropertiesException e) {
                        throw new PluginException(String.format("Unable to resolve placeholder ('%s') of the SU '%s'.",
                                entry.getValue(), suInstance.getName()), e);
                    }
                }

                // Store the properties file
                Utils.storePropertiesFile(properties, propertiesFile, componentInstance.getName(), this.logger);

                // Signal the component to reload its properties file
                try {
                    this.connectToContainer(this.retrieveContainerInstance(suInstance));
                    try {
                        this.artifactAdministration.reloadConfiguration(componentInstance.getName());
                    } finally {
                        this.containerAdministration.disconnect();
                    }
                } catch (final ContainerAdministrationException | ArtifactAdministrationException e) {
                    throw new PluginException(e);
                }

            } else {
                throw new PluginException(String.format(
                        "Unable to create or write into the properties file ('%s') of component '%s'.",
                        propertiesFileName, componentInstance.getName()));
            }
        }
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
    protected final Instance retrieveContainerInstance(final Instance suInstance) throws PluginException {

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
