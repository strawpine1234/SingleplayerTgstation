import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { CargoCatalog } from './Cargo/CargoCatalog';

type Data = {
  points: number;
  self_paid: boolean;
  status: string;
  pad: string;
  pad_ready: boolean;
  total: number;
  orders: { id: string; name: string; cost: number; payer: string }[];
};

export const BluespaceCargo = () => {
  const { act, data } = useBackend<Data>();
  const [checkout, setCheckout] = useState(false);

  return (
    <Window width={900} height={780}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <NoticeBox>{data.status}</NoticeBox>
            <Section title="Bluespace Cargo">
              <LabeledList>
                <LabeledList.Item label="Cargo budget">
                  {data.points} cr
                </LabeledList.Item>
                <LabeledList.Item
                  label="Receiving pad"
                  color={data.pad_ready ? 'good' : 'label'}
                >
                  {data.pad}
                </LabeledList.Item>
                <LabeledList.Item label="New orders paid by">
                  <Button
                    icon="id-card"
                    selected={data.self_paid}
                    onClick={() => act('toggleprivate')}
                  >
                    {data.self_paid ? 'Personal account' : 'Cargo budget'}
                  </Button>
                </LabeledList.Item>
              </LabeledList>
              <Box color="label" mt={1}>
                Link a pad by using a multitool on the BSC pad, then on this
                console. Keep the pad and nearby floor clear for deliveries.
              </Box>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab selected={!checkout} onClick={() => setCheckout(false)}>
                Catalogue
              </Tabs.Tab>
              <Tabs.Tab selected={checkout} onClick={() => setCheckout(true)}>
                Checkout ({data.orders.length})
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {checkout ? (
              <Section
                title={`Cart total: ${data.total} cr`}
                fill
                scrollable
                buttons={
                  <Button
                    icon="bolt"
                    disabled={!data.pad_ready || data.orders.length === 0}
                    onClick={() => act('checkout')}
                  >
                    Checkout & teleport
                  </Button>
                }
              >
                {data.orders.length === 0 && (
                  <Box color="label">Your cart is empty.</Box>
                )}
                <Table>
                  {data.orders.map((order) => (
                    <Table.Row key={order.id}>
                      <Table.Cell>
                        {order.name}
                        <Box color="label">{order.payer}</Box>
                      </Table.Cell>
                      <Table.Cell textAlign="right">{order.cost} cr</Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          icon="times"
                          onClick={() => act('remove', { id: order.id })}
                        >
                          Remove
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            ) : (
              <CargoCatalog />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
