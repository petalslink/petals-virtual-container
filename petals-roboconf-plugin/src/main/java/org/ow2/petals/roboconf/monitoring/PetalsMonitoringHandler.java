/**
 * Copyright (c) 2015-2017 Linagora
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
package org.ow2.petals.roboconf.monitoring;

import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_IP;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPASSWORD;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPORT;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXUSER;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_CONTAINER;

import java.io.IOException;
import java.util.Map;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.management.AttributeNotFoundException;
import javax.management.InstanceNotFoundException;
import javax.management.MBeanException;
import javax.management.MalformedObjectNameException;
import javax.management.ObjectName;
import javax.management.ReflectionException;

import org.ow2.petals.jmx.api.api.exception.ConnectionErrorException;
import org.ow2.petals.jmx.api.impl.JMXConnection;

import net.roboconf.agent.monitoring.api.IMonitoringHandler;
import net.roboconf.core.model.beans.Component;
import net.roboconf.core.model.beans.Instance;
import net.roboconf.core.model.helpers.InstanceHelpers;
import net.roboconf.messaging.api.messages.from_agent_to_dm.MsgNotifAutonomic;

/**
 * The Roboconf monitoring handler for Petals ESB
 * 
 * @author Christophe DENEUX - Linagora
 *
 */
public class PetalsMonitoringHandler implements IMonitoringHandler {

    private static final String HANDLER_NAME = "petals";

    private static final String ATTRIBUTE = "attribute";

    private static final String CONDITION_PATTERN = "(==|=|>=|>|<=|<)\\s+(\\S+)";

    private static final String WHOLE_PATTERN_EXPR = ATTRIBUTE + "\\s+(\\S+)\\s+" + "(\\S+)" + "\\s+"
            + CONDITION_PATTERN;

    private static final Pattern WHOLE_PATTERN = Pattern.compile(WHOLE_PATTERN_EXPR, Pattern.CASE_INSENSITIVE);

    private final Logger logger = Logger.getLogger(getClass().getName());

    private String applicationName;

    private String scopedInstancePath;

    private String eventId;

    private Instance currentAssociatedInstance;

    private String mBeanName;

    private String attributeName;

    private String conditionOperator;

    private String conditionThreshold;

    @Override
    public String getName() {
        return HANDLER_NAME;
    }

    @Override
    public void setAgentId(final String applicationName, final String scopedInstancePath) {
        this.applicationName = applicationName;
        this.scopedInstancePath = scopedInstancePath;
    }

    @Override
    public void reset(final Instance associatedInstance, final String eventId, final String rawRulesText) {
        this.currentAssociatedInstance = associatedInstance;
        this.eventId = eventId;

        final Matcher m = WHOLE_PATTERN.matcher(rawRulesText);
        if (m.find()) {
            this.mBeanName = m.group(1);
            this.attributeName = m.group(2);
            this.conditionOperator = m.group(3);
            this.conditionThreshold = m.group(4);

        } else {
            this.logger
                    .severe(String
                            .format("Invalid content for the 'petals' handler in the agent's monitoring: '%s' does not match the pattern '%s'.",
                                    rawRulesText, WHOLE_PATTERN_EXPR));
            this.mBeanName = null;
            this.attributeName = null;
            this.conditionOperator = null;
            this.conditionThreshold = null;
        }
    }

    @Override
    public MsgNotifAutonomic process() {

        if (this.mBeanName != null && this.attributeName != null && this.conditionOperator != null
                && this.conditionThreshold != null) {
            try {
                final JMXConnection jmxConnection = this.connect(this.currentAssociatedInstance);
                try {

                    final Object attributeValue = jmxConnection.getMBeanServerConnection().getAttribute(
                            new ObjectName(this.mBeanName), this.attributeName);
                    if (attributeValue != null) {
                        final String valueAsString = attributeValue.toString();
                        this.logger.fine(String.format("Event '%s': Attribute value of '%s' is '%s'", this.eventId,
                                this.attributeName, valueAsString));
                        if (this.evalCondition(valueAsString)) {
                            return new MsgNotifAutonomic(this.applicationName, this.scopedInstancePath, this.eventId,
                                    valueAsString);
                        } else {
                            return null;
                        }
                    } else {
                        this.logger.warning(String.format("Null value returned for attribute '%s' of '%s'",
                                this.attributeName, this.mBeanName));
                        return null;
                    }
                } finally {
                    jmxConnection.disconnect();
                }
            } catch (final ConnectionErrorException | AttributeNotFoundException | InstanceNotFoundException
                    | MalformedObjectNameException | MBeanException | ReflectionException | IOException e) {
                this.logger.log(Level.SEVERE, e.getMessage(), e);
                return null;
            }
        } else {
            return null;
        }
    }

    /**
     * @param value
     * @return <code>true</code> if the value verifies the condition
     */
    private boolean evalCondition(final String value) {

        try {
            final Double doubleValue = Double.parseDouble(value);
            final Double thresholdValue = Double.parseDouble(this.conditionThreshold);

            // Do not use arithmetic operators with doubles...
            final int comparison = doubleValue.compareTo(thresholdValue);
            if (">".equals(this.conditionOperator)) {
                return comparison > 0;
            } else if (">=".equals(this.conditionOperator)) {
                return comparison >= 0;
            } else if ("<".equals(this.conditionOperator)) {
                return comparison < 0;
            } else if ("<=".equals(this.conditionOperator)) {
                return comparison <= 0;
            } else {
                return comparison == 0;
            }
        } catch (final NumberFormatException e) {
            if ("==".equals(this.conditionOperator) || "=".equals(this.conditionOperator)) {
                return Objects.equals(value, this.conditionThreshold);
            } else {
                return false;
            }
        }
    }

    /**
     * Establishes the JMX connection to the right Petals container, retrieved from the Roboconf component instance
     * 
     * @param instance
     *            The Roboconf instance measured. Not {@code null}
     * @return A JMX connection
     * @throws ConnectionErrorException
     *             An error occurs on JMX connection
     */
    private JMXConnection connect(final Instance instance) throws ConnectionErrorException {

        // TODO: Perhaps review how to retrieve container exported variables when
        // https://github.com/roboconf/roboconf-platform/issues/184 will be fixed

        assert instance != null;

        Instance curInstance = instance;
        Instance containerInstance = null;
        while (containerInstance == null && curInstance != null) {
            Component curComponent = curInstance.getComponent();
            while (containerInstance == null && curComponent != null) {
                if (curComponent.getName().equals(ROBOCONF_COMPONENT_ABTRACT_CONTAINER)) {
                    containerInstance = curInstance;
                } else {
                    curComponent = curComponent.getExtendedComponent();
                }
            }
            curInstance = curInstance.getParent();
        }

        if (containerInstance == null) {
            throw new ConnectionErrorException(
                    String.format(
                            "Unable to retrieve the Roboconf component associated to the Petals ESB container in the Roboconf graph. The instance '%s' must have a parent inherited from '%s' or must be inherited from '%s'.",
                            instance.getName(), ROBOCONF_COMPONENT_ABTRACT_CONTAINER,
                            ROBOCONF_COMPONENT_ABTRACT_CONTAINER));
        }

        final Map<String, String> containerExportedVariables = InstanceHelpers
                .findAllExportedVariables(containerInstance);
        final String hostname = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_IP);
        final String jmxPort = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXPORT);
        final String jmxUser = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXUSER);
        final String jmxPassword = containerExportedVariables.get(CONTAINER_VARIABLE_NAME_JMXPASSWORD);
        if (hostname == null || hostname.isEmpty() || jmxPort == null || jmxPort.isEmpty() || jmxUser == null
                || jmxPassword == null) {
            throw new ConnectionErrorException("An exported variable is missing. Available exported variables are: "
                    + containerExportedVariables);
        } else {
            this.logger.fine("Exported variables of container: " + containerExportedVariables);
        }

        return new JMXConnection(hostname, Integer.parseInt(jmxPort), jmxUser, jmxPassword);
    }

    public String getMBeanName() {
        return this.mBeanName;
    }

    public String getAttributeName() {
        return this.attributeName;
    }

    public String getConditionOperator() {
        return this.conditionOperator;
    }

    public String getConditionThreshold() {
        return this.conditionThreshold;
    }

}
