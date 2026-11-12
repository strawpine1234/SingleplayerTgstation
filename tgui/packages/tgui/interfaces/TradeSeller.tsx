import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  mode: 'items' | 'gas';
  balance: number;
  earned: number;
  status: string;
  capacity?: number;
  items?: { id: string; name: string; value: number }[];
  enabled?: boolean;
  connected?: boolean;
  moles_sold?: number;
  gases?: { name: string; price: number; moles: number }[];
};

const amount = (value: number) => value.toFixed(2);

export const TradeSeller = () => {
  const { act, data } = useBackend<Data>();
  const items = data.items || [];
  const gasMode = data.mode === 'gas';

  return (
    <Window width={650} height={600}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <NoticeBox>{data.status}</NoticeBox>
            <Section
              title={gasMode ? 'Gas Seller' : 'Item Seller'}
              buttons={
                <Button
                  icon="money-bill"
                  disabled={data.balance < 1}
                  tooltip="Withdraw whole credits as a holochip. Fractional credits stay in the machine."
                  onClick={() => act('withdraw')}
                >
                  Withdraw holochip
                </Button>
              }
            >
              <LabeledList>
                <LabeledList.Item label="Available credits">
                  {amount(data.balance)} cr
                </LabeledList.Item>
                <LabeledList.Item label="Lifetime sales">
                  {amount(data.earned)} cr
                </LabeledList.Item>
                {gasMode && (
                  <LabeledList.Item label="Gas sold">
                    {amount(data.moles_sold || 0)} mol
                  </LabeledList.Item>
                )}
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            {gasMode ? (
              <Section
                title="Pipe intake"
                fill
                scrollable
                buttons={
                  <Button
                    icon={data.enabled ? 'pause' : 'play'}
                    selected={data.enabled}
                    onClick={() => act('toggle')}
                  >
                    {data.enabled ? 'Stop selling' : 'Start selling'}
                  </Button>
                }
              >
                <Box color="label" mb={1}>
                  {data.connected
                    ? 'Pipe connected.'
                    : 'Connect a pipe to the intake.'}{' '}
                  Gas is sold automatically while enabled, using its base price
                  per mole. Unpriced gases remain in the intake.
                </Box>
                <Table>
                  <Table.Row header>
                    <Table.Cell>Gas</Table.Cell>
                    <Table.Cell textAlign="right">Credits / mol</Table.Cell>
                    <Table.Cell textAlign="right">Intake (mol)</Table.Cell>
                  </Table.Row>
                  {(data.gases || []).map((gas) => (
                    <Table.Row key={gas.name}>
                      <Table.Cell>{gas.name}</Table.Cell>
                      <Table.Cell textAlign="right">
                        {gas.price > 0 ? amount(gas.price) : 'Not purchased'}
                      </Table.Cell>
                      <Table.Cell textAlign="right">
                        {amount(gas.moles)}
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            ) : (
              <Section
                title={`Stored items (${items.length}/${data.capacity})`}
                fill
                scrollable
                buttons={
                  <Button
                    icon="dollar-sign"
                    disabled={items.length === 0}
                    onClick={() => act('sell')}
                  >
                    Sell stored items
                  </Button>
                }
              >
                <Box color="label" mb={1}>
                  Insert empty items to appraise them. Prices follow the cargo
                  export market and can change as items are sold. Items with no
                  export value are not accepted.
                </Box>
                <Table>
                  {items.map((item) => (
                    <Table.Row key={item.id}>
                      <Table.Cell>{item.name}</Table.Cell>
                      <Table.Cell textAlign="right">{item.value} cr</Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          icon="eject"
                          onClick={() => act('eject', { id: item.id })}
                        >
                          Eject
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
