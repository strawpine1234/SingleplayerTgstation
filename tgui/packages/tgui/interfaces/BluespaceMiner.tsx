import { Box, Button, LabeledList, ProgressBar, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Resource = { name: string; path: string };
type Data = {
  enabled: boolean;
  powered: boolean;
  atmosphere_valid: boolean;
  temperature: number;
  pressure: number;
  purity: number;
  progress: number;
  interval: number;
  resource: string;
  resources: Resource[];
  auto_deposit: boolean;
  silo_connected: boolean;
  total_produced: number;
  power_usage: number;
  production: Record<string, number>;
};

export const BluespaceMiner = () => {
  const { act, data } = useBackend<Data>();
  const {
    enabled, powered, atmosphere_valid, temperature, pressure, purity,
    progress, interval, resource, resources, auto_deposit,
    silo_connected, total_produced, power_usage, production,
  } = data;
  const operating = enabled && powered && atmosphere_valid;
  return (
    <Window width={520} height={670} title="Bluespace Resource Miner">
      <Window.Content scrollable>
        <Section title="Extraction Control" buttons={
          <Button icon={enabled ? 'pause' : 'play'} color={enabled ? 'red' : 'green'}
            onClick={() => act('toggle_power')}>
            {enabled ? 'Stop Mining' : 'Start Mining'}
          </Button>
        }>
          <LabeledList>
            <LabeledList.Item label="Status">
              <Box color={operating ? 'good' : 'average'}>
                {operating ? 'Extracting' : !enabled ? 'Paused' : !powered ? 'No Power' : 'Atmosphere Invalid'}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Cycle Time">{interval} seconds per sheet</LabeledList.Item>
            <LabeledList.Item label="Power Demand">{power_usage} W (active)</LabeledList.Item>
          </LabeledList>
          <ProgressBar value={progress} minValue={0} maxValue={interval}>
            {progress.toFixed(1)} / {interval} s
          </ProgressBar>
        </Section>
        <Section title="Atmospheric Conditions">
          <LabeledList>
            <LabeledList.Item label="Temperature">
              <Box color={temperature < 120 ? 'good' : 'bad'}>{temperature.toFixed(1)} K (required &lt; 120 K)</Box>
            </LabeledList.Item>
            <LabeledList.Item label="Pressure">
              <Box color={pressure >= 100 ? 'good' : 'bad'}>{pressure.toFixed(1)} kPa (required ≥ 100 kPa)</Box>
            </LabeledList.Item>
            <LabeledList.Item label="Plasma Purity">
              <Box color={purity >= 99.9 ? 'good' : 'bad'}>{purity.toFixed(2)}% (required ≥ 99.9%)</Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Resource Selection">
          <Stack wrap>
            <Stack.Item>
              <Button selected={resource === 'Random'} onClick={() => act('select_resource', { path: 'Random' })}>Random</Button>
            </Stack.Item>
            {resources.map((item) => (
              <Stack.Item key={item.path}>
                <Button selected={resource === item.name} onClick={() => act('select_resource', { path: item.path })}>
                  {item.name}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
        <Section title="Ore Silo" buttons={
          <Button icon="database" selected={auto_deposit} onClick={() => act('toggle_silo')}>
            {auto_deposit ? 'Auto Deposit On' : 'Auto Deposit Off'}
          </Button>
        }>
          <Box color={silo_connected ? 'good' : 'average'}>
            {silo_connected ? 'Station ore silo available' : 'No station ore silo detected; sheets drop locally'}
          </Box>
        </Section>
        <Section title="Production Statistics">
          <LabeledList>
            <LabeledList.Item label="Total Sheets">{total_produced}</LabeledList.Item>
            {Object.entries(production || {}).map(([name, count]) => (
              <LabeledList.Item key={name} label={name}>{count}</LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
