import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  powered: boolean;
  busy: boolean;
  backend_ready: boolean;
  reset_count: number;
  last_request: string;
  last_requester: string;
  last_request_time: number;
  requirements: string[];
};

export const LavalandRegenerator = () => {
  const { act, data } = useBackend<Data>();
  const {
    powered,
    busy,
    backend_ready,
    reset_count,
    last_request,
    last_requester,
    requirements,
  } = data;
  return (
    <Window width={520} height={530} title="Bluespace Terraforming Array">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Array Status">
              <LabeledList>
                <LabeledList.Item label="Electrical Power">
                  {powered ? 'Online' : 'Offline'}
                </LabeledList.Item>
                <LabeledList.Item label="Regeneration Core">
                  {backend_ready ? 'Ready' : 'Safety interlock engaged'}
                </LabeledList.Item>
                <LabeledList.Item label="Successful Resets">
                  {reset_count}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Full Lavaland Regeneration">
              <Box mb={2}>
                A full reset would replace the Lavaland expedition zone,
                including terrain, ore deposits, ruins, fauna, and bosses.
                Anything built or left behind there would be lost.
              </Box>
              <Button
                icon="rotate"
                color="red"
                disabled={!powered || busy || !backend_ready}
                onClick={() => act('request_reset')}
              >
                {busy ? 'Regeneration in progress' : 'Regenerate Lavaland'}
              </Button>
              {!backend_ready && (
                <Box mt={2} color="bad">
                  Locked: live map regeneration has not been implemented or
                  validated. This machine will not alter Lavaland.
                </Box>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Required Safety Checks">
              {requirements.map((requirement) => (
                <Box key={requirement} mb={1}>
                  • {requirement}
                </Box>
              ))}
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Request History">
              <LabeledList>
                <LabeledList.Item label="Last Requester">
                  {last_requester}
                </LabeledList.Item>
                <LabeledList.Item label="Last Result">
                  {last_request}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
