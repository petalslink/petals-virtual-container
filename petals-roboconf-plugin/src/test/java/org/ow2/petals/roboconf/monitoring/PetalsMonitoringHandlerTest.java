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
package org.ow2.petals.roboconf.monitoring;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_IP;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPASSWORD;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXPORT;
import static org.ow2.petals.roboconf.Constants.CONTAINER_VARIABLE_NAME_JMXUSER;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_CONTAINER;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT;
import static org.ow2.petals.roboconf.Constants.ROBOCONF_COMPONENT_BC_COMPONENT;

import javax.management.InstanceAlreadyExistsException;
import javax.management.InstanceNotFoundException;
import javax.management.MBeanException;
import javax.management.MalformedObjectNameException;
import javax.management.NotCompliantMBeanException;
import javax.management.RuntimeOperationsException;
import javax.management.modelmbean.InvalidTargetObjectTypeException;

import net.roboconf.core.model.beans.Component;
import net.roboconf.core.model.beans.Instance;

import org.apache.mina.util.AvailablePortFinder;
import org.junit.Rule;
import org.junit.Test;
import org.ow2.petals.jmx.api.api.JMXClient;
import org.ow2.petals.jmx.api.impl.EmbeddedJmxServerConnector;
import org.ow2.petals.jmx.api.impl.mbean.monitoring.component.framework.ComponentMonitoringService;

/**
 * Unit test of {@link PetalsMonitoringHandler}
 * 
 * @author Christophe DENEUX - Linagora
 *
 */
public class PetalsMonitoringHandlerTest {

    private static final String EVENT_NAME = "whatever";

    private static final String APP_NAME = "app";

    private static final String SCOPED_INSTANCE_PATH = "/root";

    private static final String COMPONENT_ID = "petals-bc-soap";

    @Rule
    public final EmbeddedJmxServerConnector embeddedJmxSrvCon = new EmbeddedJmxServerConnector(
            AvailablePortFinder.getNextAvailable(JMXClient.DEFAULT_PORT));

    @Test
    public void test() throws InstanceAlreadyExistsException, NotCompliantMBeanException, RuntimeOperationsException,
            InstanceNotFoundException, MalformedObjectNameException, MBeanException, InvalidTargetObjectTypeException {

        // Initialize the MBean part
        final int messageExchangeProcessorThreadPoolAllocatedThreadsCurrent = 123;
        final ComponentMonitoringService compMonitSvc = new ComponentMonitoringService();
        compMonitSvc
                .setMessageExchangeProcessorThreadPoolAllocatedThreadsCurrent(messageExchangeProcessorThreadPoolAllocatedThreadsCurrent);
        this.embeddedJmxSrvCon.registerComponentMonitoringService(compMonitSvc, COMPONENT_ID);

        // Initialize the Roboconf instance that is measured
        final Component abstractContainerComponent = new Component(ROBOCONF_COMPONENT_ABTRACT_CONTAINER);
        final Component containerComponent = new Component("my-container-component");
        containerComponent.extendComponent(abstractContainerComponent);
        final Component abstractJbiComponentComponent = new Component(ROBOCONF_COMPONENT_ABTRACT_JBI_COMPONENT);
        final Component bcComponent = new Component(ROBOCONF_COMPONENT_BC_COMPONENT);
        bcComponent.extendComponent(abstractJbiComponentComponent);
        final Component bcSoapComponent = new Component("PetalsBCSoap");
        bcSoapComponent.extendComponent(bcComponent);
        final Instance containerInstance = new Instance("my-container");
        containerInstance.component(containerComponent);
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_IP, "localhost");
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_JMXPORT,
                Integer.toString(this.embeddedJmxSrvCon.getJmxPort()));
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_JMXUSER, "petals");
        containerInstance.overriddenExports.put(CONTAINER_VARIABLE_NAME_JMXPASSWORD, "petals");
        final Instance bcSoapInstance = new Instance(COMPONENT_ID);
        bcSoapInstance.component(bcSoapComponent);
        bcSoapInstance.parent(containerInstance);

        final PetalsMonitoringHandler monitoringHandler = new PetalsMonitoringHandler();
        monitoringHandler.setAgentId(APP_NAME, SCOPED_INSTANCE_PATH);
        final String mBeanName = "org.ow2.petals:type=custom,name=monitoring_" + COMPONENT_ID;
        final String attributeName = "MessageExchangeProcessorThreadPoolAllocatedThreadsCurrent";
        final String query = "attribute " + mBeanName + " " + attributeName + " ";

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "= 0");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("=", monitoringHandler.getConditionOperator());
        assertEquals("0", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "= "
                + messageExchangeProcessorThreadPoolAllocatedThreadsCurrent);
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("=", monitoringHandler.getConditionOperator());
        assertEquals(Integer.toString(messageExchangeProcessorThreadPoolAllocatedThreadsCurrent),
                monitoringHandler.getConditionThreshold());
        assertNotNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "== 0");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("==", monitoringHandler.getConditionOperator());
        assertEquals("0", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "== "
                + messageExchangeProcessorThreadPoolAllocatedThreadsCurrent);
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("==", monitoringHandler.getConditionOperator());
        assertEquals(Integer.toString(messageExchangeProcessorThreadPoolAllocatedThreadsCurrent),
                monitoringHandler.getConditionThreshold());
        assertNotNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + ">= 10.0");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals(">=", monitoringHandler.getConditionOperator());
        assertEquals("10.0", monitoringHandler.getConditionThreshold());
        assertNotNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + ">= 1000.0");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals(">=", monitoringHandler.getConditionOperator());
        assertEquals("1000.0", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "<   toto ");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("<", monitoringHandler.getConditionOperator());
        assertEquals("toto", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "== 'this'");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("==", monitoringHandler.getConditionOperator());
        assertEquals("'this'", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "<= 0");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("<=", monitoringHandler.getConditionOperator());
        assertEquals("0", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "<= 300");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("<=", monitoringHandler.getConditionOperator());
        assertEquals("300", monitoringHandler.getConditionThreshold());
        assertNotNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "< 0");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("<", monitoringHandler.getConditionOperator());
        assertEquals("0", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "< 200");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals("<", monitoringHandler.getConditionOperator());
        assertEquals("200", monitoringHandler.getConditionThreshold());
        assertNotNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "> 11235");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals(">", monitoringHandler.getConditionOperator());
        assertEquals("11235", monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "> 112");
        assertEquals(mBeanName, monitoringHandler.getMBeanName());
        assertEquals(attributeName, monitoringHandler.getAttributeName());
        assertEquals(">", monitoringHandler.getConditionOperator());
        assertEquals("112", monitoringHandler.getConditionThreshold());
        assertNotNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + ">== 11235");
        assertNull(monitoringHandler.getMBeanName());
        assertNull(attributeName, monitoringHandler.getAttributeName());
        assertNull(monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.getConditionOperator());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "<== 11235");
        assertNull(monitoringHandler.getMBeanName());
        assertNull(attributeName, monitoringHandler.getAttributeName());
        assertNull(monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.getConditionOperator());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + ">11235");
        assertNull(monitoringHandler.getMBeanName());
        assertNull(attributeName, monitoringHandler.getAttributeName());
        assertNull(monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.getConditionOperator());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "<11235");
        assertNull(monitoringHandler.getMBeanName());
        assertNull(attributeName, monitoringHandler.getAttributeName());
        assertNull(monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.getConditionOperator());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "=11235");
        assertNull(monitoringHandler.getMBeanName());
        assertNull(attributeName, monitoringHandler.getAttributeName());
        assertNull(monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.getConditionOperator());
        assertNull(monitoringHandler.process());

        monitoringHandler.reset(bcSoapInstance, EVENT_NAME, query + "==11235");
        assertNull(monitoringHandler.getMBeanName());
        assertNull(attributeName, monitoringHandler.getAttributeName());
        assertNull(monitoringHandler.getConditionThreshold());
        assertNull(monitoringHandler.getConditionOperator());
        assertNull(monitoringHandler.process());
    }

}
